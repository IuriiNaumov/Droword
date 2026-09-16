import Foundation
import SwiftUI
import Combine

extension Notification.Name {
    static let wordsEnriched = Notification.Name("wordsEnriched")

    static let triggerEnrichment = Notification.Name("triggerEnrichment")
}

@MainActor
final class WordEnrichmentService {
    private let store: WordsStore
    private let languageStore: LanguageStore
    private var observeTask: Task<Void, Never>?
    private var triggerTask: Task<Void, Never>?
    private var isEnriching = false

    private var isPremium: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.isPremium)
    }

    init(store: WordsStore, languageStore: LanguageStore) {
        self.store = store
        self.languageStore = languageStore
        startObserving()
    }

    deinit {
        observeTask?.cancel()
        triggerTask?.cancel()
    }

    private func startObserving() {
        if NetworkMonitor.shared.isConnected {
            Task { await enrichPendingWords() }
        }

        observeTask = Task { [weak self] in
            guard let self else { return }
            var wasConnected = NetworkMonitor.shared.isConnected
            for await connected in NetworkMonitor.shared.$isConnected.values {
                guard !Task.isCancelled else { return }
                if connected && !wasConnected {
                    await self.enrichPendingWords()
                }
                wasConnected = connected
            }
        }

        triggerTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .triggerEnrichment) {
                guard let self else { return }
                self.retryEnrichment()
            }
        }
    }

    func retryEnrichment() {
        guard NetworkMonitor.shared.isConnected else { return }
        Task { await enrichPendingWords() }
    }

    private func enrichPendingWords() async {
        guard !isEnriching else { return }
        isEnriching = true
        defer { isEnriching = false }

        let pending = store.words.filter { $0.needsEnrichment }
        guard !pending.isEmpty else { return }

        var enrichedNames: [String] = []

        for word in pending {
            guard NetworkMonitor.shared.isConnected else { break }

            if !isPremium && !DailyLimitsManager.canTranslate { break }

            do {
                let result = try await translateWithClaude(word: word.word, languageStore: languageStore)

                if !isPremium {
                    DailyLimitsManager.recordTranslation()
                }

                store.enrichWord(
                    id: word.id,
                    translation: result.translation,
                    example: result.example,
                    type: result.type.lowercased(),
                    explanation: result.explanation,
                    breakdown: result.breakdown,
                    transcription: result.transcription,
                    examples: result.examples ?? [result.example],
                    collocations: result.collocations ?? []
                )
                enrichedNames.append(word.word)
            } catch {
                continue
            }
        }

        if !enrichedNames.isEmpty {
            NotificationCenter.default.post(
                name: .wordsEnriched,
                object: nil,
                userInfo: ["words": enrichedNames]
            )
        }
    }
}
