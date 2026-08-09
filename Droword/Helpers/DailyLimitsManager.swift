import Foundation

struct DailyLimitsManager {
    static var maxFreeTranslations: Int {
        let firstUseDateStr = UserDefaults.standard.string(forKey: AppStorageKeys.firstUseDate) ?? ""
        guard !firstUseDateStr.isEmpty,
              let firstUse = DateFormatting.dayFormatter.date(from: firstUseDateStr) else {
            return 7
        }
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: firstUse, to: Date()).day ?? 0
        return daysSinceInstall <= 7 ? 7 : 3
    }
    static let maxFreeTTS = 10
    static let maxFreeSuggestionFetches = 2
    static let maxFreePhotoScans = 1
    /// A pedagogical cap (not a paywall): learning too many brand-new words in a
    /// single day floods future review sessions. Popular SRS apps default to a
    /// similar daily intake. Applies to everyone.
    static let maxNewWordsPerDay = 12

    private static let dateKey = "dailyLimits.date"
    private static let translationsKey = "dailyLimits.translations"
    private static let ttsKey = "dailyLimits.tts"
    private static let goldenKey = "dailyLimits.goldenFetches"
    private static let photoScansKey = "dailyLimits.photoScans"
    private static let newWordsKey = "dailyLimits.newWords"

    private static func resetIfNeeded() {
        let today = DateFormatting.todayString

        if UserDefaults.standard.string(forKey: dateKey) != today {
            UserDefaults.standard.set(today, forKey: dateKey)
            UserDefaults.standard.set(0, forKey: translationsKey)
            UserDefaults.standard.set(0, forKey: ttsKey)
            UserDefaults.standard.set(0, forKey: goldenKey)
            UserDefaults.standard.set(0, forKey: photoScansKey)
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

    static var canPlayTTS: Bool {
        ttsUsedToday < maxFreeTTS
    }

    static var ttsRemaining: Int {
        max(0, maxFreeTTS - ttsUsedToday)
    }

    static func recordTTS() {
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: ttsKey)
        UserDefaults.standard.set(current + 1, forKey: ttsKey)
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
}
