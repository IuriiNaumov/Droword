import Foundation
import UserNotifications

private let friendlyBodies: [String] = [
    "Let's grow your vocab — five minutes is all it takes ✨",
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

private let inactivityBodies: [String] = [
    "It's been a while — your words are waiting!",
    "A quick review keeps words fresh. Come back?",
    "Don't let your progress fade — even 2 minutes help.",
    "Your vocabulary misses you. Let's pick up where you left off!"
]

private var rotatingIndex: Int {
    get { UserDefaults.standard.integer(forKey: "notif.rotate.index") }
    set { UserDefaults.standard.set(newValue, forKey: "notif.rotate.index") }
}

private func randomContent(tagName: String?) -> (title: String, body: String) {
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
        center.removePendingNotificationRequests(withIdentifiers: [
            "daily.reminder.morning",
            "daily.reminder.evening"
        ])

        scheduleDailyReminder(hour: 9, minute: 0, tagName: tagName, identifier: "daily.reminder.morning")
        scheduleDailyReminder(hour: 19, minute: 0, tagName: tagName, identifier: "daily.reminder.evening")
    }

    func scheduleDueWordsReminder(dueCount: Int, hour: Int = 12, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["smart.due.words"])

        guard dueCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Words waiting for you"
        let wordUnit = dueCount == 1 ? "word" : "words"
        content.body = "You have \(dueCount) \(wordUnit) ready for review. A quick session keeps them fresh!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "smart.due.words", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleStreakAtRiskReminder(currentStreak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak.at.risk"])

        guard currentStreak >= 2 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak!"
        content.body = "You're on a \(currentStreak)-day streak. Practice today to keep it going!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak.at.risk", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelStreakAtRiskReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak.at.risk"])
    }

    func scheduleWordQuizReminder(word: String, translation: String, after seconds: TimeInterval = 14400) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["word.quiz.contextual"])

        let content = UNMutableNotificationContent()
        content.title = "Do you remember?"
        content.body = "What does \"\(word)\" mean? Tap to check → \(translation)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "word.quiz.contextual", content: content, trigger: trigger)
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

    func scheduleStreakMilestone(streak: Int) {
        let milestones = [7, 30, 100, 365]
        guard milestones.contains(streak) else { return }
        guard UserDefaults.standard.bool(forKey: "notifStreakMilestones") else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Streak milestone!"
        content.body = "You've been learning for \(streak) days in a row. Keep going!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "streak.milestone.\(streak)", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleDailyGoalCompletion() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Daily goal reached!"
        content.body = "Awesome, you've hit your word goal for today."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "daily.goal.done.\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
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
        for (i, d) in daysOffsets.enumerated() {
            let id = "inactive.\(d)d"
            let fire = Calendar.current.date(byAdding: .day, value: d, to: lastActive) ?? Date().addingTimeInterval(Double(d) * 86400)
            if fire < Date() { continue }

            let content = UNMutableNotificationContent()
            let pair = randomContent(tagName: nil)
            content.title = pair.title
            content.body = inactivityBodies[i % inactivityBodies.count]
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, fire.timeIntervalSinceNow), repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
