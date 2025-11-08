import Foundation
import SwiftUI
import Combine

@MainActor
final class GoldenWordsStore: ObservableObject {
    @Published var goldenWords: [SuggestedWord] = []
    @Published var topic: String? = nil
    @Published var isLoading = false

    func fetchSuggestions(basedOn words: [StoredWord]) async {
        guard !words.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let baseWords = words.map { $0.word }
            let result = try await fetchSuggestionsWithTopic(words: baseWords)
            self.topic = result.topic
            self.goldenWords = result.suggestions
        } catch {
            self.topic = nil
            self.goldenWords = []
        }
    }

    func accept(_ word: SuggestedWord, store: WordsStore) {
        let newWord = StoredWord(
            word: word.word,
            type: word.type ?? "существительное",
            translation: word.translation,
            example: word.example ?? "—",
            tag: "Golden"
        )
        store.add(newWord)
        goldenWords.removeAll { $0.id == word.id }
    }

    func skip(_ suggestion: SuggestedWord) {
        goldenWords.removeAll { $0.id == suggestion.id }
    }
}
