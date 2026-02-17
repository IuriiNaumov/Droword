import Foundation
import UserNotifications

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
        content.title = "Время повторить слова"
        if let tagName, !tagName.isEmpty {
            content.body = "Повторите слова по тегу \"\(tagName)\""
        } else {
            content.body = "Пора повторить слова"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let id = identifier ?? "daily.reminder.\(hour).\(minute).\(tagName ?? "")"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleOneTimeReminder(after seconds: TimeInterval, tagName: String? = nil, identifier: String = UUID().uuidString) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Время повторить слова"
        if let tagName, !tagName.isEmpty {
            content.body = "Повторите слова по тегу \"\(tagName)\""
        } else {
            content.body = "Пора повторить слова"
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
}
