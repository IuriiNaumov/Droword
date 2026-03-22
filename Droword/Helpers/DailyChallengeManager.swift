import Foundation
import Combine

enum ChallengeType: String, Codable, CaseIterable {
    case addWords       // "Add N words today"
    case perfectQuiz    // "Complete a quiz with 100% score"
    case practiceQuiz   // "Complete N quizzes"
    case reviewWords    // "Review N due words"
    case studyTime      // "Study for N minutes"
    case addTaggedWords // "Add N words with a tag"

    var icon: String {
        switch self {
        case .addWords:       return "plus.circle.fill"
        case .perfectQuiz:    return "star.fill"
        case .practiceQuiz:   return "brain.head.profile"
        case .reviewWords:    return "arrow.clockwise"
        case .studyTime:      return "clock.fill"
        case .addTaggedWords: return "tag.fill"
        }
    }
}

struct DailyChallenge: Codable, Identifiable {
    let id: UUID
    let type: ChallengeType
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let date: String // "yyyy-MM-dd"

    var isCompleted: Bool { currentValue >= targetValue }
    var progress: Double { min(1.0, Double(currentValue) / Double(max(1, targetValue))) }
}

@MainActor
final class DailyChallengeManager: ObservableObject {
    static let shared = DailyChallengeManager()

    @Published private(set) var challenges: [DailyChallenge] = []

    private let storageKey = "DailyChallengeManager.challenges"
    private let lastDateKey = "DailyChallengeManager.lastDate"
    private let totalCompletedKey = "DailyChallengeManager.totalCompleted"

    @Published private(set) var totalCompleted: Int = 0

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private init() {
        totalCompleted = UserDefaults.standard.integer(forKey: totalCompletedKey)
        loadOrGenerate()
    }

    var todayString: String {
        Self.dateFormatter.string(from: Date())
    }

    var allCompleted: Bool {
        challenges.allSatisfy { $0.isCompleted }
    }

    var completedCount: Int {
        challenges.filter { $0.isCompleted }.count
    }

    // MARK: - Progress updates

    func recordWordsAdded(count: Int) {
        updateChallenge(of: .addWords, increment: count)
        updateChallenge(of: .addTaggedWords, increment: 0) // handled separately
    }

    func recordTaggedWordAdded() {
        updateChallenge(of: .addTaggedWords, increment: 1)
    }

    func recordQuizCompleted(score: Int, total: Int) {
        updateChallenge(of: .practiceQuiz, increment: 1)
        if score == total && total > 0 {
            updateChallenge(of: .perfectQuiz, increment: 1)
        }
    }

    func recordWordsReviewed(count: Int) {
        updateChallenge(of: .reviewWords, increment: count)
    }

    func updateStudyMinutes(_ totalMinutesToday: Int) {
        guard let idx = challenges.firstIndex(where: { $0.type == .studyTime }) else { return }
        let wasCompleted = challenges[idx].isCompleted
        challenges[idx].currentValue = totalMinutesToday
        if !wasCompleted && challenges[idx].isCompleted {
            totalCompleted += 1
            UserDefaults.standard.set(totalCompleted, forKey: totalCompletedKey)
        }
        save()
    }

    // MARK: - Internal

    private func updateChallenge(of type: ChallengeType, increment: Int) {
        guard let idx = challenges.firstIndex(where: { $0.type == type && !$0.isCompleted }) else { return }
        let wasCompleted = challenges[idx].isCompleted
        challenges[idx].currentValue += increment
        if !wasCompleted && challenges[idx].isCompleted {
            totalCompleted += 1
            UserDefaults.standard.set(totalCompleted, forKey: totalCompletedKey)
        }
        save()
    }

    private func loadOrGenerate() {
        let today = todayString
        let lastDate = UserDefaults.standard.string(forKey: lastDateKey) ?? ""

        if lastDate == today, let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DailyChallenge].self, from: data) {
            challenges = decoded
        } else {
            challenges = generateChallenges(for: today)
            UserDefaults.standard.set(today, forKey: lastDateKey)
            save()
        }
    }

    func refreshIfNeeded() {
        let today = todayString
        let lastDate = UserDefaults.standard.string(forKey: lastDateKey) ?? ""
        if lastDate != today {
            challenges = generateChallenges(for: today)
            UserDefaults.standard.set(today, forKey: lastDateKey)
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// The daily word goal challenge (always first)
    var dailyGoalChallenge: DailyChallenge? {
        challenges.first(where: { $0.type == .addWords })
    }

    // MARK: - Challenge generation

    private func generateChallenges(for date: String) -> [DailyChallenge] {
        // Always include addWords as the daily goal
        let goalConfig = challengeConfig(for: .addWords)
        let goalChallenge = DailyChallenge(
            id: UUID(),
            type: .addWords,
            title: goalConfig.title,
            description: goalConfig.description,
            targetValue: goalConfig.target,
            currentValue: 0,
            date: date
        )

        // Pick 2 more random challenge types (excluding addWords)
        let otherTypes = ChallengeType.allCases.filter { $0 != .addWords }.shuffled()
        let extras = Array(otherTypes.prefix(2)).map { type in
            let config = challengeConfig(for: type)
            return DailyChallenge(
                id: UUID(),
                type: type,
                title: config.title,
                description: config.description,
                targetValue: config.target,
                currentValue: 0,
                date: date
            )
        }

        return [goalChallenge] + extras
    }

    private func challengeConfig(for type: ChallengeType) -> (title: String, description: String, target: Int) {
        switch type {
        case .addWords:
            let count = [3, 5, 7].randomElement()!
            return ("Word Collector", "Add \(count) new words", count)

        case .perfectQuiz:
            return ("Perfect Score", "Complete a quiz with 100%", 1)

        case .practiceQuiz:
            let count = [2, 3].randomElement()!
            return ("Quiz Machine", "Complete \(count) quizzes", count)

        case .reviewWords:
            let count = [5, 8, 10].randomElement()!
            return ("Memory Keeper", "Review \(count) due words", count)

        case .studyTime:
            let minutes = [5, 10, 15].randomElement()!
            return ("Dedicated Learner", "Study for \(minutes) minutes", minutes)

        case .addTaggedWords:
            let count = [2, 3].randomElement()!
            return ("Organizer", "Add \(count) tagged words", count)
        }
    }
}
