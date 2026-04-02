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

        exerciseTypes = [:]

        let matchingCandidateIndex: Int? = queue.count >= 4 ? Int.random(in: 0..<queue.count) : nil

        let sentenceCandidates = queue.indices.filter { i in
            let item = queue[i]
            guard let ex = item.example, !ex.isEmpty else { return false }
            let words = ex.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            return words.count >= 3 && words.count <= 12
        }
        let sentenceBuildingIndex: Int? = sentenceCandidates.filter { $0 != matchingCandidateIndex }.randomElement()

        for (index, item) in queue.enumerated() {
            if index == matchingCandidateIndex {
                exerciseTypes[item.id] = .matching
                continue
            }
            if index == sentenceBuildingIndex {
                exerciseTypes[item.id] = .sentenceBuilding
                continue
            }

            let reps = wordReps[item.id] ?? 0
            let isClozeEligible = item.example != nil
                && !item.example!.isEmpty
                && item.example!.localizedCaseInsensitiveContains(item.word)

            if reps >= 2 {
                if isClozeEligible {
                    exerciseTypes[item.id] = Bool.random() ? .typing : .cloze
                } else {
                    exerciseTypes[item.id] = .typing
                }
            } else if isClozeEligible {
                exerciseTypes[item.id] = ExerciseType.allCases.randomElement() ?? .multipleChoice
            } else {
                exerciseTypes[item.id] = Bool.random() ? .multipleChoice : .typing
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
        if reversed {
            let pool = allWords
                .map { $0.word }
                .filter { !$0.isEmpty && $0.lowercased() != item.word.lowercased() }
            let unique = Array(Set(pool))
            return Array(unique.shuffled().prefix(3))
        } else {
            let pool = allWords
                .compactMap { $0.translation }
                .filter { !$0.isEmpty && $0.lowercased() != item.translation.lowercased() }
            let unique = Array(Set(pool))
            return Array(unique.shuffled().prefix(3))
        }
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
            orderedResults: orderedResults
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
            return (uuid, type)
        })
        directionMap = Dictionary(uniqueKeysWithValues: snapshot.directionMap.compactMap { key, val in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, val)
        })
        orderedResults = snapshot.orderedResults
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
        ef = max(1.3, ef)

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
