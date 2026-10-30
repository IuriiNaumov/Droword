import Foundation

struct DailyLimitsManager {
    static var maxFreeTranslations: Int {
        let firstUseDateStr = UserDefaults.standard.string(forKey: AppStorageKeys.firstUseDate) ?? ""
        guard !firstUseDateStr.isEmpty,
              let firstUse = DateFormatting.dayFormatter.date(from: firstUseDateStr) else {
            return TranslationLimits.maxFreeTranslations(firstUse: nil)
        }
        return TranslationLimits.maxFreeTranslations(firstUse: firstUse)
    }
    static let maxFreeTTS = 10
    static let maxFreeSuggestionFetches = 4
    static let maxFreePhotoScans = 3
    static let maxFreeStories = 2

    static let maxNewWordsPerDay = 12

    private static let dateKey = "dailyLimits.date"
    private static let translationsKey = "dailyLimits.translations"
    private static let ttsKey = "dailyLimits.tts"
    private static let ttsHeardKey = "dailyLimits.ttsHeard"
    private static let goldenKey = "dailyLimits.goldenFetches"
    private static let photoScansKey = "dailyLimits.photoScans"
    private static let storiesKey = "dailyLimits.stories"
    private static let newWordsKey = "dailyLimits.newWords"

    private static func resetIfNeeded() {
        let today = DateFormatting.todayString

        if UserDefaults.standard.string(forKey: dateKey) != today {
            UserDefaults.standard.set(today, forKey: dateKey)
            UserDefaults.standard.set(0, forKey: translationsKey)
            UserDefaults.standard.set(0, forKey: ttsKey)
            UserDefaults.standard.set([String](), forKey: ttsHeardKey)
            UserDefaults.standard.set(0, forKey: goldenKey)
            UserDefaults.standard.set(0, forKey: photoScansKey)
            UserDefaults.standard.set(0, forKey: storiesKey)
            UserDefaults.standard.set(0, forKey: newWordsKey)
        }
    }

    static var newWordsIntroducedToday: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: newWordsKey)
    }

    static var newWordsRemainingToday: Int {
        max(0, maxNewWordsPerDay - newWordsIntroducedToday)
    }

    static func recordNewWordsIntroduced(_ count: Int) {
        guard count > 0 else { return }
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: newWordsKey)
        UserDefaults.standard.set(current + count, forKey: newWordsKey)
    }

    static var translationsUsedToday: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: translationsKey)
    }

    static var canTranslate: Bool {
        translationsUsedToday < maxFreeTranslations
    }

    static var translationsRemaining: Int {
        max(0, maxFreeTranslations - translationsUsedToday)
    }

    static func recordTranslation() {
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: translationsKey)
        UserDefaults.standard.set(current + 1, forKey: translationsKey)
    }

    static var ttsUsedToday: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: ttsKey)
    }

    static func canPlayTTS(for text: String) -> Bool {
        if hasHeardTTS(text) { return true }
        return ttsUsedToday < maxFreeTTS
    }

    static var ttsRemaining: Int {
        max(0, maxFreeTTS - ttsUsedToday)
    }

    static func recordTTS(for text: String) {
        resetIfNeeded()
        let key = heardKey(for: text)
        guard !key.isEmpty else { return }
        var heard = heardTexts()
        if heard.contains(key) { return }
        heard.insert(key)
        UserDefaults.standard.set(Array(heard), forKey: ttsHeardKey)
        let current = UserDefaults.standard.integer(forKey: ttsKey)
        UserDefaults.standard.set(current + 1, forKey: ttsKey)
    }

    private static func hasHeardTTS(_ text: String) -> Bool {
        resetIfNeeded()
        let key = heardKey(for: text)
        guard !key.isEmpty else { return false }
        return heardTexts().contains(key)
    }

    private static func heardTexts() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: ttsHeardKey) ?? [])
    }

    private static func heardKey(for text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static var suggestionFetchesToday: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: goldenKey)
    }

    static var canFetchSuggestions: Bool {
        suggestionFetchesToday < maxFreeSuggestionFetches
    }

    static func recordSuggestionFetch() {
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: goldenKey)
        UserDefaults.standard.set(current + 1, forKey: goldenKey)
    }

    static var photoScansUsedToday: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: photoScansKey)
    }

    static var canScanPhoto: Bool {
        photoScansUsedToday < maxFreePhotoScans
    }

    static func recordPhotoScan() {
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: photoScansKey)
        UserDefaults.standard.set(current + 1, forKey: photoScansKey)
    }

    static var storiesUsedToday: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: storiesKey)
    }

    static var canGenerateStory: Bool {
        storiesUsedToday < maxFreeStories
    }

    static var storiesRemaining: Int {
        max(0, maxFreeStories - storiesUsedToday)
    }

    static func recordStory() {
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: storiesKey)
        UserDefaults.standard.set(current + 1, forKey: storiesKey)
    }
}
