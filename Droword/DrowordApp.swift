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
    @StateObject private var golden = GoldenWordsStore()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var badgeStore = BadgeStore()

    @AppStorage("appAppearance") private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage("notifDailyReminders") private var dailyReminders: Bool = true
    @AppStorage("isPremium") private var isPremium: Bool = false
    @AppStorage("hasUsedTrial") private var hasUsedTrial: Bool = false
    @AppStorage("trialStartDate") private var trialStartDate: String = ""
    @Environment(\.scenePhase) private var scenePhase

    private let notificationDelegate = NotificationDelegate()
    @State private var enrichmentService: WordEnrichmentService?
    @StateObject private var studyTimeTracker = StudyTimeTracker.shared

    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    init() {
        warmUpKeyboard()
        warmUpAudioSession()
        warmUpGPT()
        preloadFonts()
        setupNotifications()
        checkTrialPeriod()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.colorScheme)
                .animation(.easeInOut(duration: 0.4), value: themeStore.palette)
                .environmentObject(store)
                .environmentObject(golden)
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
        }
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = notificationDelegate

        NotificationManager.shared.requestAuthorization { granted in
            guard granted else { return }
            let lastActiveDay = UserDefaults.standard.string(forKey: "lastActiveDay") ?? ""
            if !lastActiveDay.isEmpty {
                let df = DateFormatter()
                df.calendar = Calendar(identifier: .gregorian)
                df.dateFormat = "yyyy-MM-dd"
                if let lastDate = df.date(from: lastActiveDay) {
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

    private func warmUpGPT() {
        let premium = UserDefaults.standard.bool(forKey: "isPremium")
        guard premium else { return }
        let langStore = LanguageStore()
        Task.detached(priority: .background) {
            _ = try? await translateWithGPT(word: "hola", languageStore: langStore)
        }
    }

    private func preloadFonts() {
        _ = UIFont(name: "Poppins-Bold", size: 14)
        _ = UIFont(name: "Poppins-Regular", size: 14)
    }

    private func scheduleSmartNotifications() {
        guard dailyReminders else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let dueCount = store.words.filter { w in
            if let due = w.dueDate { return due <= today } else { return true }
        }.count

        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: Date())
        let lastActiveDay = UserDefaults.standard.string(forKey: "lastActiveDay") ?? ""
        let hasPracticedToday = lastActiveDay == todayStr
        let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")

        let dueWordInfos = store.words
            .filter { w in
                guard let due = w.dueDate, due <= today else { return false }
                guard let tr = w.translation, !tr.isEmpty else { return false }
                return true
            }
            .map { DueWordInfo(word: $0.word, translation: $0.translation!) }

        NotificationManager.shared.scheduleDaily(
            dueCount: dueCount,
            currentStreak: currentStreak,
            hasPracticedToday: hasPracticedToday,
            dueWords: dueWordInfos
        )
    }

    private static let trialDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private func checkTrialPeriod() {
        let df = Self.trialDateFormatter

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
            if !hasPurchased {
                isPremium = false
                UserDefaults.standard.set(false, forKey: "seasonalEffectsEnabled")
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
