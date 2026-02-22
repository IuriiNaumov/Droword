import Foundation
import UserNotifications

private let friendlyBodies: [String] = [
    "Let’s grow your vocab — five minutes is all it takes ✨",
    "Time to refresh a few words. Quick and simple!",
    "I prepared a mini‑session for you. Jump in?",
    "Your words miss you. Ready to review?",
    "One small step today — closer to your goal."
]

private let friendlyTitles: [String] = [
    "Time to review",
    "Language minute",
    "Your vocab calls",
    "Quick refresh",
    "Small step today"
]

private var rotatingIndex: Int {
    get { UserDefaults.standard.integer(forKey: "notif.rotate.index") }
    set { UserDefaults.standard.set(newValue, forKey: "notif.rotate.index") }
}

private func randomContent(tagName: String?) -> (title: String, body: String) {
    // Cycle through titles/bodies to alternate messages
    var idx = rotatingIndex
    let title = friendlyTitles[idx % friendlyTitles.count]
    let baseBody = friendlyBodies[idx % friendlyBodies.count]
    idx = (idx + 1) % max(friendlyTitles.count, friendlyBodies.count)
    rotatingIndex = idx

    var body = baseBody
    if let tagName, !tagName.isEmpty {
        body += " for \"\(tagName)\""
    }
    return (title, body)
}

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            completion?(granted)
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int, tagName: String? = nil, identifier: String? = nil) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        let pair = randomContent(tagName: tagName)
        content.title = pair.title
        content.body = pair.body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let id = identifier ?? "daily.reminder.\(hour).\(minute).\(tagName ?? "")"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleTwiceDaily(tagName: String? = nil) {
        let center = UNUserNotificationCenter.current()
        // Remove previous twice-daily identifiers to avoid duplicates
        center.removePendingNotificationRequests(withIdentifiers: [
            "daily.reminder.morning",
            "daily.reminder.evening"
        ])

        // Morning at 9:00
        scheduleDailyReminder(hour: 9, minute: 0, tagName: tagName, identifier: "daily.reminder.morning")
        // Evening at 19:00
        scheduleDailyReminder(hour: 19, minute: 0, tagName: tagName, identifier: "daily.reminder.evening")
    }

    func scheduleOneTimeReminder(after seconds: TimeInterval, tagName: String? = nil, identifier: String = UUID().uuidString) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        let pair = randomContent(tagName: tagName)
        content.title = pair.title
        content.body = pair.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    func scheduleInactivityReminders(lastActive: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "inactive.3d", "inactive.7d", "inactive.14d", "inactive.30d"
        ])

        let daysOffsets = [3, 7, 14, 30]
        for d in daysOffsets {
            let id = "inactive.\(d)d"
            let fire = Calendar.current.date(byAdding: .day, value: d, to: lastActive) ?? Date().addingTimeInterval(Double(d) * 86400)
            if fire < Date() { continue }

            let content = UNMutableNotificationContent()
            let pair = randomContent(tagName: nil)
            content.title = pair.title
            content.body = pair.body + " — давно не виделись!"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, fire.timeIntervalSinceNow), repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
