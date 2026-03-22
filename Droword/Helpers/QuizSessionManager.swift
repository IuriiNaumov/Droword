import SwiftUI
import Combine

final class QuizSessionManager: ObservableObject {

    enum ExerciseType: CaseIterable {
        case multipleChoice
        case typing
        case cloze
    }

    struct QuizItem: Identifiable {
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

    func prepareSession(from words: [StoredWord], filterTag: String? = nil) {
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

        let items = Array(due.prefix(maxSessionSize)).map { w in
            QuizItem(
                id: w.id,
                word: w.word,
                translation: w.translation ?? "",
                transcription: w.transcription,
                tag: w.tag,
                example: w.example
            )
        }

        queue = items.shuffled()
        currentIndex = 0
        correctCount = 0
        isComplete = false
    }

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

        let items = Array(due.prefix(maxSessionSize)).map { w in
            QuizItem(
                id: w.id,
                word: w.word,
                translation: w.translation ?? "",
                transcription: w.transcription,
                tag: w.tag,
                example: w.example
            )
        }

        queue = items.shuffled()
        currentIndex = 0
        correctCount = 0
        isComplete = false

        exerciseTypes = [:]
        for item in queue {
            let isClozeEligible = item.example != nil
                && !item.example!.isEmpty
                && item.example!.localizedCaseInsensitiveContains(item.word)

            if isClozeEligible {
                exerciseTypes[item.id] = ExerciseType.allCases.randomElement()!
            } else {
                exerciseTypes[item.id] = Bool.random() ? .multipleChoice : .typing
            }
        }
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
        if correct { correctCount += 1 }
    }

    func advance() {
        if currentIndex + 1 >= queue.count {
            isComplete = true
        } else {
            currentIndex += 1
        }
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
