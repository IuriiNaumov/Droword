import Foundation
import Combine
import WidgetKit

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

let appGroupID = "group.com.droword.shared"

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
    private static let migrationKey = "WordsStore.migratedToAppGroup"
    private var hasLoaded = false
    private var saveTask: Task<Void, Never>?

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
    }

    init() {
        migrateIfNeeded()
        load()
    }

    func add(_ word: StoredWord) {
        words.append(word)
        totalWordsAdded += 1
        UserDefaults.standard.set(true, forKey: AppStorageKeys.hasEverAddedWord)
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

    private func migrateIfNeeded() {
        let shared = sharedDefaults
        guard !shared.bool(forKey: Self.migrationKey) else { return }

        let standard = UserDefaults.standard

        if let data = standard.data(forKey: storageKey) {
            shared.set(data, forKey: storageKey)
        }

        let total = standard.integer(forKey: totalKey)
        if total > 0 {
            shared.set(total, forKey: totalKey)
        }

        shared.set(true, forKey: Self.migrationKey)
    }

    private func load() {
        let defaults = sharedDefaults

        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) {
            words = decoded
        }

        totalWordsAdded = defaults.integer(forKey: totalKey)
        hasLoaded = true
    }

    func reloadFromDisk() {
        let defaults = sharedDefaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) {
            if decoded != words {
                hasLoaded = false
                words = decoded
                totalWordsAdded = defaults.integer(forKey: totalKey)
                hasLoaded = true
            }
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let self else { return }
            let copy = self.words
            let total = self.totalWordsAdded
            let storageKey = self.storageKey
            let totalKey = self.totalKey
            let defaults = self.sharedDefaults
            Task.detached(priority: .utility) {
                if let data = try? JSONEncoder().encode(copy) {
                    await MainActor.run {
                        defaults.set(data, forKey: storageKey)
                    }
                }
                await MainActor.run {
                    defaults.set(total, forKey: totalKey)
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
            self.syncStreakToAppGroup()
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


    static func computeCurrentStreak(from words: [StoredWord]) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dates = Set(words.map { cal.startOfDay(for: $0.dateAdded) })

        var streak = 0
        var day = today
        while dates.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    func syncStreakToAppGroup() {
        let streak = Self.computeCurrentStreak(from: words)
        sharedDefaults.set(streak, forKey: AppStorageKeys.currentStreak)
        UserDefaults.standard.set(streak, forKey: AppStorageKeys.currentStreak)
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
