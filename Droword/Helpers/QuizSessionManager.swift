import SwiftUI
import Combine

final class QuizSessionManager: ObservableObject {

    struct QuizItem: Identifiable {
        let id: UUID
        let word: String
        let translation: String
        let transcription: String?
        let tag: String?
    }

    @Published var queue: [QuizItem] = []
    @Published var currentIndex: Int = 0
    @Published var correctCount: Int = 0
    @Published var isComplete: Bool = false

    private let maxSessionSize = 10

    var currentItem: QuizItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var total: Int { queue.count }

    // MARK: - Session

    func prepareSession(from words: [StoredWord]) {
        let items = words
            .filter { $0.translation != nil && !$0.translation!.isEmpty }
            .map { w in
                QuizItem(
                    id: w.id,
                    word: w.word,
                    translation: w.translation ?? "",
                    transcription: w.transcription,
                    tag: w.tag
                )
            }
            .shuffled()

        queue = Array(items.prefix(maxSessionSize))
        currentIndex = 0
        correctCount = 0
        isComplete = false
    }

    func distractors(for item: QuizItem, from allWords: [StoredWord]) -> [String] {
        let pool = allWords
            .compactMap { $0.translation }
            .filter { !$0.isEmpty && $0.lowercased() != item.translation.lowercased() }

        let unique = Array(Set(pool))
        return Array(unique.shuffled().prefix(3))
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

    // MARK: - SM-2 Bridge

    static func applyScheduling(
        for wordID: UUID,
        correct: Bool,
        store: WordsStore,
        languageStore: LanguageStore
    ) {
        guard let w = store.words.first(where: { $0.id == wordID }) else { return }

        var ef = max(1.3, w.easeFactor)
        var reps = w.repetitions
        var ivl = w.intervalDays
        var lapses = w.lapses

        let q: Double = correct ? 4 : 1

        // Update learningScore (EMA)
        let quality: Double = correct ? 0.7 : 0.0
        let alpha = 0.06
        let prev = languageStore.learningScore
        languageStore.learningScore = max(0.0, min(1.0, prev * (1 - alpha) + quality * alpha))

        // SM-2 EF update
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
