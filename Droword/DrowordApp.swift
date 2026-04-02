import SwiftUI
import AVFoundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}

@main
struct DrowordApp: App {
    @StateObject private var store = WordsStore()
    @StateObject private var suggested = SuggestedWordsStore()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var badgeStore = BadgeStore()

    @AppStorage(AppStorageKeys.appAppearance) private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasUsedTrial) private var hasUsedTrial: Bool = false
    @AppStorage(AppStorageKeys.trialStartDate) private var trialStartDate: String = ""
    @Environment(\.scenePhase) private var scenePhase

    private let notificationDelegate = NotificationDelegate()
    @State private var enrichmentService: WordEnrichmentService?
    @StateObject private var studyTimeTracker = StudyTimeTracker.shared

    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    init() {
        migrateNotificationSettings()
        configureNavigationBarTint()
        warmUpKeyboard()
        warmUpAudioSession()
        warmUpClaude()
        preloadFonts()
        setupNotifications()
        checkTrialPeriod()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.colorScheme)
                .tint(themeStore.mainAccentColor)
                .animation(.easeInOut(duration: 0.4), value: themeStore.palette)
                .environmentObject(store)
                .environmentObject(suggested)
                .environmentObject(languageStore)
                .environmentObject(themeStore)
                .environmentObject(badgeStore)
                .environmentObject(studyTimeTracker)
                .task {
                    if enrichmentService == nil {
                        enrichmentService = WordEnrichmentService(store: store, languageStore: languageStore)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        store.reloadFromDisk()
                        enrichmentService?.retryEnrichment()
                        scheduleSmartNotifications()
                        checkTrialPeriod()
                        if !isPremium && themeStore.palette == .duolingo {
                            themeStore.set(.colorful)
                        }
                        studyTimeTracker.resumeSession()
                    case .inactive, .background:
                        let todayMins = studyTimeTracker.todaySeconds / 60
                        DailyChallengeManager.shared.updateStudyMinutes(todayMins)
                        studyTimeTracker.pauseSession()
                    @unknown default:
                        break
                    }
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onChange(of: themeStore.palette) { _, newPalette in
                    Self.applyNavigationTint(for: newPalette.rawValue)
                }
        }
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = notificationDelegate

        NotificationManager.shared.requestAuthorization { granted in
            guard granted else { return }
            let lastActiveDay = UserDefaults.standard.string(forKey: AppStorageKeys.lastActiveDay) ?? ""
            if !lastActiveDay.isEmpty {
                if let lastDate = DateFormatting.dayFormatter.date(from: lastActiveDay) {
                    NotificationManager.shared.scheduleInactivityReminders(lastActive: lastDate)
                }
            }
        }
    }

    private func warmUpKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let textField = UITextField()
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.addSubview(textField)
            textField.becomeFirstResponder()
            textField.resignFirstResponder()
            textField.removeFromSuperview()
        }
    }

    private func warmUpAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: .mixWithOthers)
        try? session.setActive(true)
    }

    private func warmUpClaude() {
        let premium = UserDefaults.standard.bool(forKey: AppStorageKeys.isPremium)
        guard premium else { return }
        let langStore = LanguageStore()
        Task.detached(priority: .background) {
            _ = try? await translateWithClaude(word: "hola", languageStore: langStore)
        }
    }

    private static func applyNavigationTint(for paletteRaw: String) {
        let tintColor: UIColor
        switch paletteRaw {
        case "duolingo":
            tintColor = UIColor(red: 0.345, green: 0.8, blue: 0.008, alpha: 1)
        case "monochrome":
            tintColor = UIColor(named: "MonoMedium") ?? .gray
        default:
            tintColor = UIColor(named: "AccentBlue") ?? .systemBlue
        }
        UINavigationBar.appearance().tintColor = tintColor
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.tintColor = tintColor
                }
            }
        }
    }

    private func configureNavigationBarTint() {
        let raw = UserDefaults.standard.string(forKey: "appThemePalette") ?? "colorful"
        Self.applyNavigationTint(for: raw)
    }

    private func preloadFonts() {
        _ = UIFont(name: "Poppins-Bold", size: 14)
        _ = UIFont(name: "Poppins-Regular", size: 14)
    }

    private func scheduleSmartNotifications() {
        let prefs = NotificationPreferences.fromDefaults()
        let lastActiveDay = UserDefaults.standard.string(forKey: AppStorageKeys.lastActiveDay) ?? ""
        let lastActive = DateFormatting.dayFormatter.date(from: lastActiveDay)

        NotificationManager.shared.rescheduleAll(
            prefs: prefs,
            allWords: store.words,
            lastActiveDate: lastActive
        )
    }

    private func migrateNotificationSettings() {
        let d = UserDefaults.standard
        let migrated = d.bool(forKey: "notifSettingsMigratedV2")
        guard !migrated else { return }

        let oldDailyReminders = d.object(forKey: AppStorageKeys.notifDailyReminders) as? Bool ?? true
        let oldStreakMilestones = d.object(forKey: AppStorageKeys.notifStreakMilestones) as? Bool ?? true

        d.set(oldDailyReminders, forKey: AppStorageKeys.notifGlobalEnabled)
        d.set(oldDailyReminders, forKey: AppStorageKeys.notifDailyReminderEnabled)
        d.set(12, forKey: AppStorageKeys.notifDailyReminderHour)
        d.set(0, forKey: AppStorageKeys.notifDailyReminderMinute)
        d.set(false, forKey: AppStorageKeys.notifVocabEnabled)
        d.set(true, forKey: AppStorageKeys.notifVocabShowTranscription)
        d.set(true, forKey: AppStorageKeys.notifVocabShowTranslation)
        d.set(false, forKey: AppStorageKeys.notifVocabIncludeMastered)
        d.set(3, forKey: AppStorageKeys.notifVocabFrequency)
        d.set(9, forKey: AppStorageKeys.notifVocabStartHour)
        d.set(0, forKey: AppStorageKeys.notifVocabStartMinute)
        d.set(18, forKey: AppStorageKeys.notifVocabEndHour)
        d.set(0, forKey: AppStorageKeys.notifVocabEndMinute)
        d.set(oldStreakMilestones, forKey: AppStorageKeys.notifStreakMilestones)

        d.set(true, forKey: "notifSettingsMigratedV2")
    }

    private func checkTrialPeriod() {
        let df = DateFormatting.dayFormatter

        if !hasUsedTrial {
            hasUsedTrial = true
            trialStartDate = df.string(from: Date())
            isPremium = true
            return
        }

        guard !trialStartDate.isEmpty,
              let start = df.date(from: trialStartDate) else { return }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        if daysSinceStart > 7 && isPremium {
            let hasPurchased = UserDefaults.standard.bool(forKey: "hasRealPurchase")
            let debugOverride = UserDefaults.standard.bool(forKey: AppStorageKeys.debugPremiumOverride)
            if !hasPurchased && !debugOverride {
                isPremium = false
                UserDefaults.standard.set(false, forKey: AppStorageKeys.seasonalEffectsEnabled)
                if let savedPalette = UserDefaults.standard.string(forKey: "appThemePalette"),
                   savedPalette == ThemeStore.Palette.duolingo.rawValue {
                    UserDefaults.standard.set(ThemeStore.Palette.colorful.rawValue, forKey: "appThemePalette")
                }
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "droword", url.host == "add" else { return }

        let word = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "word" })?.value ?? ""

        NotificationCenter.default.post(
            name: .sharedWordReceived,
            object: nil,
            userInfo: ["word": word]
        )
    }
}

extension Notification.Name {
    static let sharedWordReceived = Notification.Name("sharedWordReceived")
}
