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

    @AppStorage("appAppearance") private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage("notifDailyReminders") private var dailyReminders: Bool = true

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
                .environmentObject(store)
                .environmentObject(golden)
                .environmentObject(languageStore)
                .environmentObject(themeStore)
                .task {
                    if enrichmentService == nil {
                        enrichmentService = WordEnrichmentService(store: store, languageStore: languageStore)
                    }
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
            // Schedule inactivity reminders based on last active day
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
}
