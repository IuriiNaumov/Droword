import Foundation

struct DailyLimitsManager {
    static let maxFreeTranslations = 3
    static let maxFreeTTS = 10
    static let maxFreeSuggestionFetches = 2


    private static let dateKey = "dailyLimits.date"
    private static let translationsKey = "dailyLimits.translations"
    private static let ttsKey = "dailyLimits.tts"
    private static let goldenKey = "dailyLimits.goldenFetches"

    private static func resetIfNeeded() {
        let today = DateFormatting.todayString

        if UserDefaults.standard.string(forKey: dateKey) != today {
            UserDefaults.standard.set(today, forKey: dateKey)
            UserDefaults.standard.set(0, forKey: translationsKey)
            UserDefaults.standard.set(0, forKey: ttsKey)
            UserDefaults.standard.set(0, forKey: goldenKey)
        }
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
}
