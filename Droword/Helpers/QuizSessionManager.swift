import SwiftUI
import Combine

final class QuizSessionManager: ObservableObject {

    enum ExerciseType: String, CaseIterable, Codable {
        case multipleChoice
        case typing
        case cloze
        case matching
        case sentenceBuilding
    }

    struct QuizItem: Identifiable, Codable {
        let id: UUID
        let word: String
        let translation: String
        let transcription: String?
        let tag: String?
        let example: String?
    }

    @Published var queue: [QuizItem] = []
    @Published var currentIndex: Int = 0
    @Published var correctCount: Int = 0
    @Published var isComplete: Bool = false
    @Published var exerciseTypes: [UUID: ExerciseType] = [:]
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var answerResults: [UUID: Bool] = [:]
    @Published var orderedResults: [Bool] = []
    @Published var directionMap: [UUID: Bool] = [:]
    @Published var answeredCount: Int = 0
    
    var maxSessionSize = 10
    /// The number of items in the original session (before retries are appended)
    @Published var originalTotal: Int = 0

    var currentItem: QuizItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var currentExerciseType: ExerciseType? {
        guard let item = currentItem else { return nil }
        return exerciseTypes[item.id]
    }

    var total: Int { queue.count }

    func prepareMixedSession(from words: [StoredWord], filterTag: String? = nil) {
        var filtered = words
            .filter { $0.translation != nil && !$0.translation!.isEmpty }
            .filter { $0.word.components(separatedBy: .whitespaces).count <= 3 }

        if let tag = filterTag, !tag.isEmpty {
            filtered = filtered.filter { $0.tag == tag }
        }

        let today = Calendar.current.startOfDay(for: Date())
        var due = filtered.filter { w in
            if let d = w.dueDate { return d <= today } else { return true }
        }.shuffled()
        let notDue = filtered.filter { w in
            if let d = w.dueDate { return d > today } else { return false }
        }.shuffled()

        if due.count < maxSessionSize {
            due.append(contentsOf: notDue.prefix(maxSessionSize - due.count))
        }

        let selected = Array(due.prefix(maxSessionSize))

        let items = selected.map { w in
            QuizItem(
                id: w.id,
                word: w.word,
                translation: w.translation ?? "",
                transcription: w.transcription,
                tag: w.tag,
                example: w.example
            )
        }

        let wordReps: [UUID: Int] = Dictionary(
            uniqueKeysWithValues: selected.map { ($0.id, $0.repetitions) }
        )

        queue = items.shuffled()
        currentIndex = 0
        correctCount = 0
        answeredCount = 0
        isComplete = false
        currentStreak = 0
        bestStreak = 0
        answerResults = [:]
        orderedResults = []
        originalTotal = queue.count

        exerciseTypes = [:]

        let matchingCandidateIndex: Int? = queue.count >= 4 ? Int.random(in: 0..<queue.count) : nil

        for (index, item) in queue.enumerated() {
            if index == matchingCandidateIndex {
                exerciseTypes[item.id] = .matching
                continue
            }

            let reps = wordReps[item.id] ?? 0
            let isClozeEligible = item.example != nil
                && !item.example!.isEmpty
                && item.example!.localizedCaseInsensitiveContains(item.word)

            // Progressive difficulty based on repetition count:
            // reps 0   → MC only (first encounter, recognition)
            // reps 1   → MC or typing 50/50 (reinforcement)
            // reps 2-3 → typing, or cloze if eligible (active recall)
            // reps 4+  → typing/cloze with cloze bias (context mastery)
            switch reps {
            case 0:
                exerciseTypes[item.id] = .multipleChoice
            case 1:
                exerciseTypes[item.id] = Bool.random() ? .multipleChoice : .typing
            case 2...3:
                if isClozeEligible {
                    exerciseTypes[item.id] = Bool.random() ? .typing : .cloze
                } else {
                    exerciseTypes[item.id] = .typing
                }
            default:
                if isClozeEligible {
                    // 70% cloze, 30% typing at mastery stage
                    exerciseTypes[item.id] = Int.random(in: 0..<10) < 7 ? .cloze : .typing
                } else {
                    exerciseTypes[item.id] = .typing
                }
            }
        }

        let nonCloze = queue.filter { exerciseTypes[$0.id] != .cloze }
        let halfReversed = nonCloze.count / 2
        var reversedFlags = Array(repeating: true, count: halfReversed)
            + Array(repeating: false, count: nonCloze.count - halfReversed)
        reversedFlags.shuffle()
        directionMap = [:]
        for (i, item) in nonCloze.enumerated() {
            directionMap[item.id] = reversedFlags[i]
        }
    }

    func matchingPairs(for item: QuizItem) -> [(word: String, translation: String)] {
        var pairs: [(word: String, translation: String)] = [(item.word, item.translation)]
        let others = queue.filter { $0.id != item.id }.shuffled().prefix(3)
        for other in others {
            pairs.append((other.word, other.translation))
        }
        return pairs.shuffled()
    }

    func distractors(for item: QuizItem, from allWords: [StoredWord], reversed: Bool = false) -> [String] {
        let correctAnswer: String
        let pool: [String]

        if reversed {
            correctAnswer = item.word.lowercased()
            pool = allWords
                .map { $0.word }
                .filter { !$0.isEmpty && $0.lowercased() != correctAnswer }
        } else {
            correctAnswer = item.translation.lowercased()
            pool = allWords
                .compactMap { $0.translation }
                .filter { !$0.isEmpty && $0.lowercased() != correctAnswer }
        }

        // Deduplicate by lowercased form, keep original casing
        var seen = Set<String>()
        var unique: [String] = []
        for item in pool.shuffled() {
            let key = item.lowercased()
            if seen.insert(key).inserted {
                unique.append(item)
            }
        }
        return Array(unique.prefix(3))
    }

    func recordAnswer(correct: Bool) {
        if correct {
            correctCount += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
        if let item = currentItem {
            answerResults[item.id] = correct
        }
    }

    func advance() {
        if let item = currentItem, let result = answerResults[item.id] {
            answeredCount += 1
            orderedResults.append(result)
        }
        if currentIndex + 1 >= queue.count {
            isComplete = true
        } else {
            currentIndex += 1
        }
    }

    private static let savedSessionKey = "savedQuizSession"

    private struct SessionSnapshot: Codable {
        let queue: [QuizItem]
        let currentIndex: Int
        let correctCount: Int
        let currentStreak: Int
        let bestStreak: Int
        let answeredCount: Int
        let answerResults: [String: Bool]
        let exerciseTypes: [String: String]
        let directionMap: [String: Bool]
        let orderedResults: [Bool]
        var originalTotal: Int?
    }

    func saveSession() {
        let snapshot = SessionSnapshot(
            queue: queue,
            currentIndex: currentIndex,
            correctCount: correctCount,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            answeredCount: answeredCount,
            answerResults: Dictionary(uniqueKeysWithValues: answerResults.map { ($0.key.uuidString, $0.value) }),
            exerciseTypes: Dictionary(uniqueKeysWithValues: exerciseTypes.map { ($0.key.uuidString, $0.value.rawValue) }),
            directionMap: Dictionary(uniqueKeysWithValues: directionMap.map { ($0.key.uuidString, $0.value) }),
            orderedResults: orderedResults,
            originalTotal: originalTotal
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.savedSessionKey)
        }
    }

    func restoreSession() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.savedSessionKey),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data),
              !snapshot.queue.isEmpty,
              snapshot.currentIndex < snapshot.queue.count else {
            return false
        }

        queue = snapshot.queue
        currentIndex = snapshot.currentIndex
        correctCount = snapshot.correctCount
        currentStreak = snapshot.currentStreak
        bestStreak = snapshot.bestStreak
        answeredCount = snapshot.answeredCount
        isComplete = false
        answerResults = Dictionary(uniqueKeysWithValues: snapshot.answerResults.compactMap { key, val in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, val)
        })
        exerciseTypes = Dictionary(uniqueKeysWithValues: snapshot.exerciseTypes.compactMap { key, val in
            guard let uuid = UUID(uuidString: key),
                  let type = ExerciseType(rawValue: val) else { return nil }
            // Remap removed exercise types to multipleChoice
            return (uuid, type == .sentenceBuilding ? .multipleChoice : type)
        })
        directionMap = Dictionary(uniqueKeysWithValues: snapshot.directionMap.compactMap { key, val in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, val)
        })
        orderedResults = snapshot.orderedResults
        originalTotal = snapshot.originalTotal ?? snapshot.queue.count
        return true
    }

    func clearSavedSession() {
        UserDefaults.standard.removeObject(forKey: Self.savedSessionKey)
    }

    var hasSavedSession: Bool {
        UserDefaults.standard.data(forKey: Self.savedSessionKey) != nil
    }

    static func applyScheduling(
        for wordID: UUID,
        correct: Bool,
        isAlmostCorrect: Bool = false,
        store: WordsStore,
        languageStore: LanguageStore
    ) {
        guard let w = store.words.first(where: { $0.id == wordID }) else { return }

        var ef = max(1.3, w.easeFactor)
        var reps = w.repetitions
        var ivl = w.intervalDays
        var lapses = w.lapses

        let q: Double
        if !correct {
            q = 1
        } else if isAlmostCorrect {
            q = 3
        } else {
            q = 4
        }

        let quality: Double
        if !correct {
            quality = 0.0
        } else if isAlmostCorrect {
            quality = 0.5
        } else {
            quality = 1.0
        }

        let alpha = 0.06
        let prev = languageStore.learningScore
        languageStore.learningScore = max(0.0, min(1.0, prev * (1 - alpha) + quality * alpha))

        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        ef = min(3.0, max(1.3, ef))

        let now = Date()
        let cal = Calendar.current

        if q < 3 {
            lapses += 1
            reps = 0
            ivl = 0
            let due = cal.date(byAdding: .minute, value: 10, to: now)
            store.updateScheduling(for: wordID,
                                   easeFactor: ef,
                                   intervalDays: ivl,
                                   repetitions: reps,
                                   lapses: lapses,
                                   dueDate: due)
        } else {
            reps += 1
            if reps == 1 { ivl = 1 }
            else if reps == 2 { ivl = 6 }
            else { ivl = max(1, Int(round(Double(ivl) * ef))) }
            let due = cal.date(byAdding: .day, value: ivl, to: now)
            store.updateScheduling(for: wordID,
                                   easeFactor: ef,
                                   intervalDays: ivl,
                                   repetitions: reps,
                                   lapses: lapses,
                                   dueDate: due)
        }
    }
}
