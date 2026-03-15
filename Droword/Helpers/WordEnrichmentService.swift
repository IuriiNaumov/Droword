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
        if NetworkMonitor.shared.isConnected {
            Task { await enrichPendingWords() }
        }

        observeTask = Task { [weak self] in
            var wasConnected = NetworkMonitor.shared.isConnected
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
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

                store.enrichWord(
                    id: word.id,
                    translation: result.translation,
                    example: result.example,
                    type: result.type.lowercased(),
                    explanation: result.explanation,
                    breakdown: result.breakdown,
                    transcription: result.transcription
                )
            } catch {
                continue
            }
        }
    }


}
