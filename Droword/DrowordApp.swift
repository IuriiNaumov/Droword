import SwiftUI
import UserNotifications
import UIKit
import CoreText

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        ChatSceneLaunch.consumeNotification(response.notification)
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
        setupNotifications()
        checkTrialPeriod()
        Self.registerBundledFonts()
        Task.detached(priority: .background) {
            _ = UIFont(name: "Poppins-Regular", size: 14)
            _ = UIFont(name: "Poppins-Medium", size: 14)
            _ = UIFont(name: "Poppins-SemiBold", size: 14)
            _ = UIFont(name: "Poppins-Bold", size: 14)
            _ = UIFont(name: "Poppins-Black", size: 14)
        }
    }

    private static func registerBundledFonts() {
        let files = [
            "Poppins-Regular",
            "Poppins-Medium",
            "Poppins-SemiBold",
            "Poppins-Bold",
            "Poppins-Black"
        ]
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                #if DEBUG
                print("⚠️ Missing font file in bundle: \(name).ttf")
                #endif
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            #if DEBUG
            if let error {
                print("⚠️ Font register failed \(name): \(error.takeUnretainedValue())")
            }
            #endif
        }
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
                        if !isPremium && themeStore.palette != .colorful {
                            themeStore.set(.colorful)
                        }
                        studyTimeTracker.resumeSession()
                    case .inactive, .background:
                        let todayMins = studyTimeTracker.todaySeconds / 60
                        DailyChallengeManager.shared.updateStudyMinutes(todayMins)
                        studyTimeTracker.pauseSession()
                        store.flushPendingSave()
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

        let lastActiveDay = UserDefaults.standard.string(forKey: AppStorageKeys.lastActiveDay) ?? ""
        NotificationManager.shared.runIfAuthorized {
            if let lastDate = DateFormatting.dayFormatter.date(from: lastActiveDay) {
                NotificationManager.shared.scheduleInactivityReminders(lastActive: lastDate)
            }
        }
    }

    private static func applyNavigationTint(for paletteRaw: String) {
        let tintColor: UIColor
        switch paletteRaw {
        case "duolingo":
            tintColor = UIColor(red: 0.345, green: 0.8, blue: 0.008, alpha: 1)
        case "sunset":
            tintColor = UIColor(red: 0.91, green: 0.51, blue: 0.36, alpha: 1)
        case "night":
            tintColor = UIColor(red: 0.655, green: 0.545, blue: 0.98, alpha: 1)
        case "ocean":
            tintColor = UIColor(red: 0.18, green: 0.77, blue: 0.71, alpha: 1)
        case "paper":
            tintColor = UIColor(red: 0.77, green: 0.47, blue: 0.29, alpha: 1)
        case "glass":
            tintColor = UIColor.systemBlue
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

        if !hasUsedTrial, let keychainDate = TrialKeychain.loadStartDate() {
            hasUsedTrial = true
            trialStartDate = keychainDate
        }

        guard hasUsedTrial, !trialStartDate.isEmpty,
              let start = df.date(from: trialStartDate) else { return }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        if daysSinceStart > 7 && isPremium {
            let hasPurchased = UserDefaults.standard.bool(forKey: "hasRealPurchase")
            #if DEBUG
            let debugOverride = UserDefaults.standard.bool(forKey: AppStorageKeys.debugPremiumOverride)
            #else
            let debugOverride = false
            #endif
            if !hasPurchased && !debugOverride {
                isPremium = false
                UserDefaults.standard.set(false, forKey: AppStorageKeys.seasonalEffectsEnabled)
                if let savedPalette = UserDefaults.standard.string(forKey: "appThemePalette"),
                   savedPalette != ThemeStore.Palette.colorful.rawValue {
                    UserDefaults.standard.set(ThemeStore.Palette.colorful.rawValue, forKey: "appThemePalette")
                }
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "droword" else { return }
        let host = url.host ?? ""
        if host == "add" {
            let word = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "word" })?.value ?? ""
            NotificationCenter.default.post(
                name: .sharedWordReceived,
                object: nil,
                userInfo: ["word": word]
            )
            return
        }
        if host == "chat" {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let wordId = items?.first(where: { $0.name == "id" })?.value
            let word = items?.first(where: { $0.name == "word" })?.value
            ChatSceneLaunch.store(wordId: wordId, word: word)
            NotificationCenter.default.post(
                name: .openChatScene,
                object: nil,
                userInfo: ["wordId": wordId as Any, "word": word as Any]
            )
            return
        }
        NotificationCenter.default.post(
            name: .openFromWidget,
            object: nil,
            userInfo: ["host": host]
        )
    }
}

extension Notification.Name {
    static let sharedWordReceived = Notification.Name("sharedWordReceived")
    static let copiedToClipboard = Notification.Name("copiedToClipboard")
    static let perfectQuizCompleted = Notification.Name("perfectQuizCompleted")
    static let openFromWidget = Notification.Name("openFromWidget")
    static let openAddWord = Notification.Name("openAddWord")
    static let openChatScene = Notification.Name("openChatScene")
}
