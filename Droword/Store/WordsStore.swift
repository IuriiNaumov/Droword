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
    var examples: [String] = []
    var reaction: String? = nil

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
        needsEnrichment: Bool = false,
        examples: [String] = [],
        reaction: String? = nil
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
        self.examples = examples
        self.reaction = reaction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        word = try container.decode(String.self, forKey: .word)
        type = try container.decode(String.self, forKey: .type)
        translation = try container.decodeIfPresent(String.self, forKey: .translation)
        example = try container.decodeIfPresent(String.self, forKey: .example)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        breakdown = try container.decodeIfPresent(String.self, forKey: .breakdown)
        transcription = try container.decodeIfPresent(String.self, forKey: .transcription)
        tag = try container.decodeIfPresent(String.self, forKey: .tag)
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        fromLanguage = try container.decode(String.self, forKey: .fromLanguage)
        toLanguage = try container.decode(String.self, forKey: .toLanguage)
        easeFactor = try container.decodeIfPresent(Double.self, forKey: .easeFactor) ?? 2.5
        intervalDays = try container.decodeIfPresent(Int.self, forKey: .intervalDays) ?? 0
        repetitions = try container.decodeIfPresent(Int.self, forKey: .repetitions) ?? 0
        lapses = try container.decodeIfPresent(Int.self, forKey: .lapses) ?? 0
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        needsEnrichment = try container.decodeIfPresent(Bool.self, forKey: .needsEnrichment) ?? false
        let decoded = try container.decodeIfPresent([String].self, forKey: .examples) ?? []
        if decoded.isEmpty, let ex = example {
            examples = [ex]
        } else {
            examples = decoded
        }
        reaction = try container.decodeIfPresent(String.self, forKey: .reaction)
    }
}

let appGroupID = "group.com.droword.shared"

@MainActor
final class WordsStore: ObservableObject {
    @Published private(set) var words: [StoredWord] = [] {
        didSet {
            if hasLoaded {
                revision += 1
                scheduleSave()
            }
        }
    }

    @Published private(set) var totalWordsAdded: Int = 0 {
        didSet { if hasLoaded { scheduleSave() } }
    }

    @Published private(set) var revision: Int = 0

    private let storageKey = "WordsStore.words"
    private let totalKey = "WordsStore.totalWordsAdded"
    private static let migrationKey = "WordsStore.migratedToAppGroup"
    private static let fileMigrationKey = "WordsStore.migratedToFile"
    private var hasLoaded = false
    private var saveTask: Task<Void, Never>?

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
    }

    private static var wordsFileURL: URL {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return container.appendingPathComponent("words.json")
    }

    init() {
        migrateIfNeeded()
        load()
    }

    func add(_ word: StoredWord) {
        var w = word
        if w.dueDate == nil {
            w.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }
        words.append(w)
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

        if !shared.bool(forKey: Self.migrationKey) {
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

        if !shared.bool(forKey: Self.fileMigrationKey) {
            if let data = shared.data(forKey: storageKey) {
                try? data.write(to: Self.wordsFileURL, options: .atomic)
            }
            shared.set(true, forKey: Self.fileMigrationKey)
        }
    }

    private func load() {
        // Try primary file
        if let data = try? Data(contentsOf: Self.wordsFileURL) {
            do {
                words = try JSONDecoder().decode([StoredWord].self, from: data)
                totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
                hasLoaded = true
                return
            } catch {
                #if DEBUG
                print("⚠️ WordsStore: Failed to decode words.json: \(error)")
                #endif
                // Try backup before falling through
                let backupURL = Self.wordsFileURL.deletingLastPathComponent().appendingPathComponent("words_backup.json")
                if let backupData = try? Data(contentsOf: backupURL),
                   let decoded = try? JSONDecoder().decode([StoredWord].self, from: backupData) {
                    words = decoded
                    totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
                    hasLoaded = true
                    return
                }
            }
        }

        // Fallback to UserDefaults (legacy migration path)
        if let data = sharedDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) {
            words = decoded
        }

        totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
        hasLoaded = true
    }

    func reloadFromDisk() {
        guard let data = try? Data(contentsOf: Self.wordsFileURL),
              let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) else { return }
        if decoded != words {
            hasLoaded = false
            words = decoded
            totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
            hasLoaded = true
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let self else { return }
            let copy = self.words
            let total = self.totalWordsAdded
            let totalKey = self.totalKey
            let defaults = self.sharedDefaults
            let fileURL = Self.wordsFileURL
            Task.detached(priority: .utility) {
                if let data = try? JSONEncoder().encode(copy) {
                    try? data.write(to: fileURL, options: .atomic)
                    // Keep a rolling backup
                    let backupURL = fileURL.deletingLastPathComponent().appendingPathComponent("words_backup.json")
                    try? data.write(to: backupURL, options: .atomic)
                }
                await MainActor.run {
                    defaults.set(total, forKey: totalKey)
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
            self.syncStreakToAppGroup()
        }
    }
    
    func setReaction(for id: UUID, reaction: String?) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        var w = words[idx]
        w.reaction = reaction
        words[idx] = w
    }

    func enrichWord(id: UUID, translation: String, example: String, type: String, explanation: String?, breakdown: String?, transcription: String?, examples: [String] = []) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        var w = words[idx]
        w.translation = translation
        w.example = example
        w.type = type
        w.explanation = explanation
        w.breakdown = breakdown
        w.transcription = transcription
        w.needsEnrichment = false
        if examples.isEmpty {
            w.examples = [example]
        } else {
            w.examples = examples
        }
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

    /// Computes streak allowing one gap day per 7-day window (premium freeze).
    /// Returns the streak count and the date that was frozen (if any).
    static func computeCurrentStreakWithFreeze(from words: [StoredWord]) -> (streak: Int, freezeDate: Date?) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dates = Set(words.map { cal.startOfDay(for: $0.dateAdded) })

        var streak = 0
        var day = today
        var freezeDate: Date? = nil
        let lastFreezeDateStr = UserDefaults.standard.string(forKey: AppStorageKeys.lastStreakFreezeDate) ?? ""
        let lastFreezeDay = DateFormatting.dayFormatter.date(from: lastFreezeDateStr)

        while true {
            if dates.contains(day) {
                streak += 1
            } else if freezeDate == nil {
                // Allow freeze if 7+ days since last freeze (or never frozen)
                let canFreeze: Bool
                if let lastFreeze = lastFreezeDay {
                    let daysSinceFreeze = cal.dateComponents([.day], from: lastFreeze, to: day).day ?? 0
                    canFreeze = abs(daysSinceFreeze) >= 7
                } else {
                    canFreeze = true
                }
                if canFreeze && day != today {
                    freezeDate = day
                    streak += 1
                } else {
                    break
                }
            } else {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return (streak, freezeDate)
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
