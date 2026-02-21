import Foundation
import UserNotifications

private let friendlyBodies: [String] = [
    "Давай подкачаем словарик? Пять минут — и ты молодец ✨",
    "Пора освежить пару слов. Быстро и по делу!",
    "Я приготовил тебе мини-сессию. Заглянешь?",
    "Слова скучают по тебе. Залетаем на повтор?",
    "Ещё шаг — и ты ближе к цели. Готов?"
]

private let friendlyTitles: [String] = [
    "Время повторить слова",
    "Минутка для языка",
    "Твой словарик зовёт",
    "Пора освежиться",
    "Маленький шаг сегодня"
]

private func randomContent(tagName: String?) -> (title: String, body: String) {
    let title = friendlyTitles.randomElement() ?? "Время повторить слова"
    var body = friendlyBodies.randomElement() ?? "Пора повторить слова"
    if let tagName, !tagName.isEmpty {
        body += " по тегу \"\(tagName)\""
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
