import Foundation

enum ChatScenePicker {
    static func from(
        wordId: String?,
        word: String?,
        words: [StoredWord],
        learningLanguage: String
    ) -> ChatSceneTarget? {
        if let wordId, let uuid = UUID(uuidString: wordId),
           let match = words.first(where: { $0.id == uuid }) {
            return target(from: match)
        }
        if let word, !word.isEmpty {
            let folded = word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            if let match = words.first(where: {
                $0.word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == folded
            }) {
                return target(from: match)
            }
            return ChatSceneTarget(id: UUID(), word: word, translation: "", example: nil)
        }
        return fallback(words: words, learningLanguage: learningLanguage)
    }

    static func fromLesson(items: [(id: UUID, word: String, translation: String, correct: Bool)], words: [StoredWord]) -> ChatSceneTarget? {
        let hits = items.filter(\.correct)
        let pool = hits.isEmpty ? items : hits
        guard let item = pool.first else { return nil }
        if let match = words.first(where: { $0.id == item.id }) {
            return target(from: match)
        }
        return ChatSceneTarget(id: item.id, word: item.word, translation: item.translation, example: nil)
    }

    static func fallback(words: [StoredWord], learningLanguage: String) -> ChatSceneTarget? {
        let eligible = words.filter {
            $0.fromLanguage == learningLanguage
                && !($0.translation ?? "").isEmpty
        }
        guard !eligible.isEmpty else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let due = eligible.filter { ($0.dueDate ?? .distantPast) <= today }
        let recent = eligible.sorted { $0.dateAdded > $1.dateAdded }
        return target(from: due.first ?? recent[0])
    }

    private static func target(from word: StoredWord) -> ChatSceneTarget {
        ChatSceneTarget(
            id: word.id,
            word: word.word,
            translation: word.translation ?? "",
            example: word.example
        )
    }
}
