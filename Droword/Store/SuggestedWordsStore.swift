import Foundation
import SwiftUI
import Combine

@MainActor
final class SuggestedWordsStore: ObservableObject {
    @Published var suggestedWords: [SuggestedWord] = [] {
        didSet { saveToDisk() }
    }
    @Published var topic: String? = nil {
        didSet { saveToDisk() }
    }
    @Published var isLoading = false

    private static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("suggestedWords.json")
    }()

    init() {
        loadFromDisk()
    }

    func fetchSuggestions(basedOn words: [StoredWord], languageStore: LanguageStore) async {
        guard !words.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let currentLanguage = languageStore.learningLanguage
            let relevantWords = words
                .filter { $0.fromLanguage == currentLanguage }
                .sorted { $0.dateAdded > $1.dateAdded }
                .prefix(50)
            
            guard !relevantWords.isEmpty else { return }
            
            let baseWords = relevantWords.map { $0.word }
            let allWords = words
                .filter { $0.fromLanguage == currentLanguage }
                .map { $0.word.lowercased() }
            let result = try await fetchSuggestionsWithTopic(words: baseWords, exclude: allWords, languageStore: languageStore)
            self.topic = result.topic
            self.suggestedWords = result.suggestions
        } catch {
        }
    }

    func accept(_ word: SuggestedWord, store: WordsStore, languageStore: LanguageStore) {
        let newWord = StoredWord(
            word: word.word,
            type: word.type ?? "",
            translation: word.translation,
            example: word.example,
            explanation: word.explanation,
            breakdown: word.breakdown,
            transcription: word.transcription,
            comment: nil,
            tag: "Suggested",
            fromLanguage: languageStore.nativeLanguage,
            toLanguage: languageStore.learningLanguage
        )
        store.add(newWord)
        suggestedWords.removeAll { $0.id == word.id }
    }

    func skip(_ suggestion: SuggestedWord) {
        suggestedWords.removeAll { $0.id == suggestion.id }
    }

    private struct DiskData: Codable {
        let topic: String?
        let words: [SuggestedWord]
    }

    private func saveToDisk() {
        let data = DiskData(topic: topic, words: suggestedWords)
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: Self.fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("⚠️ Failed to save suggested words: \(error)")
            #endif
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: Self.fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: Self.fileURL)
            let decoded = try JSONDecoder().decode(DiskData.self, from: data)
            self.suggestedWords = decoded.words
            self.topic = decoded.topic
        } catch {
            #if DEBUG
            print("⚠️ Failed to load suggested words: \(error)")
            #endif
        }
    }
}
