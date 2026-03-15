import Foundation

@MainActor
final class WordEnrichmentService {
    private let store: WordsStore
    private let languageStore: LanguageStore
    private var observeTask: Task<Void, Never>?

    init(store: WordsStore, languageStore: LanguageStore) {
        self.store = store
        self.languageStore = languageStore
        startObserving()
    }

    private func startObserving() {
        // Enrich on launch if connected
        if NetworkMonitor.shared.isConnected {
            Task { await enrichPendingWords() }
        }

        // Watch for connectivity changes
        observeTask = Task { [weak self] in
            var wasConnected = NetworkMonitor.shared.isConnected
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // check every 2s
                guard !Task.isCancelled, let self else { return }
                let connected = NetworkMonitor.shared.isConnected
                if connected && !wasConnected {
                    await self.enrichPendingWords()
                }
                wasConnected = connected
            }
        }
    }

    private func enrichPendingWords() async {
        let pending = store.words.filter { $0.needsEnrichment }
        guard !pending.isEmpty else { return }

        for word in pending {
            guard NetworkMonitor.shared.isConnected else { break }

            do {
                let result = try await translateWithGPT(word: word.word, languageStore: languageStore)
                let russianType = translatePartOfSpeechToRussian(result.type)

                store.enrichWord(
                    id: word.id,
                    translation: result.translation,
                    example: result.example,
                    type: russianType,
                    explanation: result.explanation,
                    breakdown: result.breakdown,
                    transcription: result.transcription
                )
            } catch {
                // Skip this word, will retry next time
                continue
            }
        }
    }

    private func translatePartOfSpeechToRussian(_ type: String?) -> String {
        guard let type = type?.lowercased() else { return "" }
        switch type {
        case "verb": return "глагол"
        case "phrase": return "фраза"
        case "noun": return "существительное"
        case "adjective": return "прилагательное"
        case "adverb": return "наречие"
        case "pronoun": return "местоимение"
        case "preposition": return "предлог"
        case "conjunction": return "союз"
        case "interjection": return "междометие"
        case "article": return "артикль"
        default: return type
        }
    }
}
