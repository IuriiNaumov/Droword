import Foundation

/// Tracks daily usage counters for free users.
/// Premium users bypass all limits.
struct DailyLimitsManager {
    static let maxFreeTranslations = 3
    static let maxFreeTTS = 10
    static let maxFreeGoldenFetches = 2  // 2 fetches × 2 words = 4 golden words

    // MARK: - Keys

    private static let dateKey = "dailyLimits.date"
    private static let translationsKey = "dailyLimits.translations"
    private static let ttsKey = "dailyLimits.tts"
    private static let goldenKey = "dailyLimits.goldenFetches"

    // MARK: - Reset if new day

    private static func resetIfNeeded() {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())

        if UserDefaults.standard.string(forKey: dateKey) != today {
            UserDefaults.standard.set(today, forKey: dateKey)
            UserDefaults.standard.set(0, forKey: translationsKey)
            UserDefaults.standard.set(0, forKey: ttsKey)
            UserDefaults.standard.set(0, forKey: goldenKey)
        }
    }

    // MARK: - Translations (AI word additions)

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

    // MARK: - TTS (play audio)

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

    // MARK: - Golden Words (suggestion fetches)

    static var goldenFetchesToday: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: goldenKey)
    }

    static var canFetchGolden: Bool {
        goldenFetchesToday < maxFreeGoldenFetches
    }

    static func recordGoldenFetch() {
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: goldenKey)
        UserDefaults.standard.set(current + 1, forKey: goldenKey)
    }
}
