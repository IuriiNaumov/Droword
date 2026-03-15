import Foundation
import Combine

struct StoredWord: Identifiable, Codable, Equatable {
    let id: UUID
    var word: String
    var type: String
    var translation: String?
    var example: String?
    var comment: String?
    var explanation: String?
    var breakdown: String?
    var transcription: String?
    var tag: String?
    var dateAdded: Date = Date()
    var fromLanguage: String
    var toLanguage: String
    var easeFactor: Double = 2.5
    var intervalDays: Int = 0
    var repetitions: Int = 0
    var lapses: Int = 0
    var dueDate: Date? = nil
    var needsEnrichment: Bool = false

    init(
        id: UUID = UUID(),
        word: String,
        type: String,
        translation: String?,
        example: String?,
        explanation: String? = nil,
        breakdown: String? = nil,
        transcription: String? = nil,
        comment: String? = nil,
        tag: String? = nil,
        dateAdded: Date = Date(),
        fromLanguage: String,
        toLanguage: String,
        easeFactor: Double = 2.5,
        intervalDays: Int = 0,
        repetitions: Int = 0,
        lapses: Int = 0,
        dueDate: Date? = nil,
        needsEnrichment: Bool = false
    ) {
        self.id = id
        self.word = word
        self.type = type
        self.translation = translation
        self.example = example
        self.explanation = explanation
        self.breakdown = breakdown
        self.transcription = transcription
        self.comment = comment
        self.tag = tag
        self.dateAdded = dateAdded
        self.fromLanguage = fromLanguage
        self.toLanguage = toLanguage
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitions = repetitions
        self.lapses = lapses
        self.dueDate = dueDate
        self.needsEnrichment = needsEnrichment
    }
}


@MainActor
final class WordsStore: ObservableObject {
    @Published private(set) var words: [StoredWord] = [] {
        didSet { if hasLoaded { scheduleSave() } }
    }

    @Published private(set) var totalWordsAdded: Int = 0 {
        didSet { if hasLoaded { scheduleSave() } }
    }

    private let storageKey = "WordsStore.words"
    private let totalKey = "WordsStore.totalWordsAdded"
    private var hasLoaded = false
    private var saveTask: Task<Void, Never>?

    init() { load() }

    func add(_ word: StoredWord) {
        words.append(word)
        totalWordsAdded += 1
    }

    func remove(_ word: StoredWord) {
        words.removeAll { $0.id == word.id }
    }

    func removeMultiple(ids: Set<UUID>) {
        words.removeAll { ids.contains($0.id) }
    }

    func clear() {
        words.removeAll()
    }

    private func load() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) {
            words = decoded
        }

        totalWordsAdded = defaults.integer(forKey: totalKey)
        hasLoaded = true
    }

    /// Debounced save — coalesces rapid changes into a single write after 0.3s
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            guard !Task.isCancelled, let self else { return }
            let copy = self.words
            let total = self.totalWordsAdded
            let storageKey = self.storageKey
            let totalKey = self.totalKey
            Task.detached(priority: .utility) {
                if let data = try? JSONEncoder().encode(copy) {
                    await MainActor.run {
                        UserDefaults.standard.set(data, forKey: storageKey)
                    }
                }
                await MainActor.run {
                    UserDefaults.standard.set(total, forKey: totalKey)
                }
            }
        }
    }
    
    func enrichWord(id: UUID, translation: String, example: String, type: String, explanation: String?, breakdown: String?, transcription: String?) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        var w = words[idx]
        w.translation = translation
        w.example = example
        w.type = type
        w.explanation = explanation
        w.breakdown = breakdown
        w.transcription = transcription
        w.needsEnrichment = false
        words[idx] = w
    }

    func updateScheduling(for id: UUID,
                          easeFactor: Double,
                          intervalDays: Int,
                          repetitions: Int,
                          lapses: Int,
                          dueDate: Date?) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        var w = words[idx]
        w.easeFactor = easeFactor
        w.intervalDays = intervalDays
        w.repetitions = repetitions
        w.lapses = lapses
        w.dueDate = dueDate
        words[idx] = w
    }
}
