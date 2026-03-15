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
    @Environment(\.scenePhase) private var scenePhase

    private let notificationDelegate = NotificationDelegate()
    @State private var enrichmentService: WordEnrichmentService?

    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    init() {
        warmUpKeyboard()
        warmUpAudioSession()
        warmUpGPT()
        preloadFonts()
        setupNotifications()
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
                .task {
                    if enrichmentService == nil {
                        enrichmentService = WordEnrichmentService(store: store, languageStore: languageStore)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        store.reloadFromDisk()
                        scheduleSmartNotifications()
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
            if self.dailyReminders {
                NotificationManager.shared.scheduleTwiceDaily()
            }
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
            UIApplication.shared.windows.first?.addSubview(textField)
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
        Task.detached(priority: .background) {
            let languageStore = LanguageStore()
            _ = try? await translateWithGPT(word: "hola", languageStore: languageStore)
        }
    }

    private func preloadFonts() {
        _ = UIFont(name: "Poppins-Bold", size: 14)
        _ = UIFont(name: "Poppins-Regular", size: 14)
    }

    private func scheduleSmartNotifications() {
        let today = Calendar.current.startOfDay(for: Date())
        let dueCount = store.words.filter { w in
            if let due = w.dueDate { return due <= today } else { return true }
        }.count
        NotificationManager.shared.scheduleDueWordsReminder(dueCount: dueCount)

        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: Date())
        let lastActiveDay = UserDefaults.standard.string(forKey: "lastActiveDay") ?? ""
        let hasPracticedToday = lastActiveDay == todayStr
        let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")

        if hasPracticedToday {
            NotificationManager.shared.cancelStreakAtRiskReminder()
        } else if currentStreak >= 2 {
            NotificationManager.shared.scheduleStreakAtRiskReminder(currentStreak: currentStreak)
        }

        if let randomDue = store.words.filter({ w in
            guard let due = w.dueDate else { return false }
            return due <= today
        }).randomElement(),
           let translation = randomDue.translation, !translation.isEmpty {
            NotificationManager.shared.scheduleWordQuizReminder(
                word: randomDue.word,
                translation: translation,
                after: 4 * 3600
            )
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
