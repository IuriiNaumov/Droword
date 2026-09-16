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
    var collocations: [String] = []
    var synonyms: [String] = []
    var antonyms: [String] = []
    var mnemonic: String? = nil
    var reaction: String? = nil

    var introduced: Bool = false

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
        collocations: [String] = [],
        synonyms: [String] = [],
        antonyms: [String] = [],
        mnemonic: String? = nil,
        reaction: String? = nil,
        introduced: Bool = false
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
        self.collocations = collocations
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.mnemonic = mnemonic
        self.reaction = reaction
        self.introduced = introduced
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
        collocations = try container.decodeIfPresent([String].self, forKey: .collocations) ?? []
        reaction = try container.decodeIfPresent(String.self, forKey: .reaction)

        introduced = try container.decodeIfPresent(Bool.self, forKey: .introduced) ?? (repetitions > 0 || intervalDays > 0)
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
    private static let autoIntroduceKey = "WordsStore.autoIntroducedPending"
    private var hasLoaded = false
    private var saveTask: Task<Void, Never>?
    private var savesSinceBackup = 0
    private var lastWidgetReloadAt: Date = .distantPast
    private var lastLoadedFileModification: Date?

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
        autoIntroducePendingWordsIfNeeded()
    }

    func add(_ word: StoredWord) {
        var w = word
        w.introduced = true
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

    private func autoIntroducePendingWordsIfNeeded() {
        let shared = sharedDefaults
        guard !shared.bool(forKey: Self.autoIntroduceKey) else { return }
        shared.set(true, forKey: Self.autoIntroduceKey)

        var copy = words
        var changed = false
        for i in copy.indices where !copy[i].introduced {
            copy[i].introduced = true
            changed = true
        }
        if changed {
            words = copy
        }
    }

    private func load() {

        if let data = try? Data(contentsOf: Self.wordsFileURL) {
            do {
                words = try JSONDecoder().decode([StoredWord].self, from: data)
                totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
                lastLoadedFileModification = Self.fileModificationDate()
                hasLoaded = true
                return
            } catch {
                #if DEBUG
                print("⚠️ WordsStore: Failed to decode words.json: \(error)")
                #endif

                let backupURL = Self.wordsFileURL.deletingLastPathComponent().appendingPathComponent("words_backup.json")
                if let backupData = try? Data(contentsOf: backupURL),
                   let decoded = try? JSONDecoder().decode([StoredWord].self, from: backupData) {
                    words = decoded
                    totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
                    lastLoadedFileModification = Self.fileModificationDate()
                    hasLoaded = true
                    return
                }
            }
        }

        if let data = sharedDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) {
            words = decoded
        }

        totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
        lastLoadedFileModification = Self.fileModificationDate()
        hasLoaded = true
    }

    private static func fileModificationDate() -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: wordsFileURL.path)
        return attrs?[.modificationDate] as? Date
    }

    func reloadFromDisk(force: Bool = false) {

        if !force,
           let mod = Self.fileModificationDate(),
           let last = lastLoadedFileModification,
           mod <= last {
            return
        }
        guard let data = try? Data(contentsOf: Self.wordsFileURL),
              let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) else {
            if force { revision += 1 }
            return
        }
        if decoded != words {
            hasLoaded = false
            words = decoded
            totalWordsAdded = sharedDefaults.integer(forKey: totalKey)
            hasLoaded = true
        } else if force {
            revision += 1
        }
        lastLoadedFileModification = Self.fileModificationDate()
    }

    func flushPendingSave() {
        saveTask?.cancel()
        saveTask = nil
        persistNow(forceBackup: true, forceWidgetReload: true)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled, let self else { return }
            self.persistNow(forceBackup: false, forceWidgetReload: false)
        }
    }

    private func persistNow(forceBackup: Bool, forceWidgetReload: Bool) {
        let copy = words
        let total = totalWordsAdded
        let totalKey = self.totalKey
        let defaults = sharedDefaults
        let fileURL = Self.wordsFileURL
        savesSinceBackup += 1
        let writeBackup = forceBackup || savesSinceBackup >= 10
        if writeBackup { savesSinceBackup = 0 }

        let shouldReloadWidget: Bool
        if forceWidgetReload {
            shouldReloadWidget = true
            lastWidgetReloadAt = Date()
        } else if Date().timeIntervalSince(lastWidgetReloadAt) >= 30 {
            shouldReloadWidget = true
            lastWidgetReloadAt = Date()
        } else {
            shouldReloadWidget = false
        }

        let streak = Self.computeCurrentStreak(from: copy)
        let widgetPayload = Self.makeWidgetSnapshot(from: copy)
        let streakKey = AppStorageKeys.currentStreak

        Task.detached(priority: .utility) {
            if let data = try? JSONEncoder().encode(copy) {
                try? data.write(to: fileURL, options: .atomic)
                if writeBackup {
                    let backupURL = fileURL.deletingLastPathComponent().appendingPathComponent("words_backup.json")
                    try? data.write(to: backupURL, options: .atomic)
                }
            }

            if let snapshotData = try? JSONEncoder().encode(widgetPayload) {
                defaults.set(snapshotData, forKey: "WordsStore.words")
            }
            defaults.set(total, forKey: totalKey)
            defaults.set(streak, forKey: streakKey)
            await MainActor.run {
                UserDefaults.standard.set(streak, forKey: streakKey)
                StudyActivityStore.shared.writeToAppGroup()
            }
            if shouldReloadWidget {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private struct WidgetSnapshotWord: Codable {
        let word: String
        let translation: String?
        let dueDate: Date?
        let dateAdded: Date
    }

    private static func makeWidgetSnapshot(from words: [StoredWord]) -> [WidgetSnapshotWord] {

        words.map {
            WidgetSnapshotWord(
                word: $0.word,
                translation: $0.translation,
                dueDate: $0.dueDate,
                dateAdded: $0.dateAdded
            )
        }
    }

    func setReaction(for id: UUID, reaction: String?) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        var w = words[idx]
        w.reaction = reaction
        words[idx] = w
    }

    func enrichWord(id: UUID, translation: String, example: String, type: String, explanation: String?, breakdown: String?, transcription: String?, examples: [String] = [], collocations: [String] = [], synonyms: [String] = [], antonyms: [String] = [], mnemonic: String? = nil) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        var w = words[idx]
        w.translation = translation
        w.example = example
        w.type = type
        w.explanation = explanation
        w.breakdown = breakdown
        w.transcription = transcription
        w.collocations = collocations
        w.synonyms = synonyms
        w.antonyms = antonyms
        w.mnemonic = mnemonic
        w.needsEnrichment = false
        if examples.isEmpty {
            w.examples = [example]
        } else {
            w.examples = examples
        }
        words[idx] = w
    }

    static func activityDays(from words: [StoredWord]) -> Set<Date> {
        StudyActivityStore.shared.ensureMigrated(from: words)
        return StudyActivityStore.shared.activityDates()
    }

    static func computeCurrentStreak(from words: [StoredWord]) -> Int {
        DayStreak.current(activityDays: activityDays(from: words))
    }

    static func computeCurrentStreakWithFreeze(from words: [StoredWord]) -> (streak: Int, freezeDate: Date?) {
        let lastFreezeDateStr = UserDefaults.standard.string(forKey: AppStorageKeys.lastStreakFreezeDate) ?? ""
        let lastFreezeDay = DateFormatting.dayFormatter.date(from: lastFreezeDateStr)
        return DayStreak.currentWithFreeze(
            activityDays: activityDays(from: words),
            lastFreezeDay: lastFreezeDay
        )
    }

    func syncStreakToAppGroup() {
        let streak = Self.computeCurrentStreak(from: words)
        sharedDefaults.set(streak, forKey: AppStorageKeys.currentStreak)
        UserDefaults.standard.set(streak, forKey: AppStorageKeys.currentStreak)
    }

    var newWords: [StoredWord] {
        words
            .filter { !$0.introduced && ($0.translation?.isEmpty == false) }
            .sorted { $0.dateAdded < $1.dateAdded }
    }

    func markIntroduced(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let now = Date()
        var copy = words
        var changed = false
        for id in ids {
            guard let idx = copy.firstIndex(where: { $0.id == id }) else { continue }
            copy[idx].introduced = true
            copy[idx].dueDate = now
            changed = true
        }
        if changed {
            words = copy
        }
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
