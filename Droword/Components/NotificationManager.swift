import Foundation
import UserNotifications


private let morningTitles = [
    "Good morning!",
    "Rise and learn",
    "Fresh start"
]

private let morningBodies = [
    "Start your day with a quick word review ✨",
    "A few minutes now — your future self will thank you!",
    "Your words are waiting. A quick session?"
]

private let afternoonTitles = [
    "Words waiting for you",
    "Quick refresh",
    "Do you remember?"
]

private let eveningTitles = [
    "Wind down with words",
    "Evening review",
    "Don't break your streak!"
]

private let eveningBodies = [
    "End the day stronger — review a few words before bed.",
    "A mini-session keeps your streak alive!",
    "One small step today — closer to your goal."
]

private let inactivityBodies = [
    "It's been a while — your words are waiting!",
    "A quick review keeps words fresh. Come back?",
    "Don't let your progress fade — even 2 minutes help.",
    "Your vocabulary misses you. Let's pick up where you left off!"
]

struct DueWordInfo {
    let word: String
    let translation: String
}


final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private static let morningID   = "daily.slot.morning"
    private static let afternoonID = "daily.slot.afternoon"
    private static let eveningID   = "daily.slot.evening"

    private static let streakMilestonePrefix = "streak.milestone"
    private static let dailyGoalID = "daily.goal.done"
    private static let inactivityPrefix = "inactive"


    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            completion?(granted)
        }
    }

    func scheduleDaily(
        dueCount: Int,
        currentStreak: Int,
        hasPracticedToday: Bool,
        dueWords: [DueWordInfo]
    ) {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers: [
            Self.morningID, Self.afternoonID, Self.eveningID
        ])

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

        if !hasPracticedToday {
            let title = morningTitles[dayOfYear % morningTitles.count]
            let body: String
            if dueCount > 0 {
                let unit = dueCount == 1 ? "word" : "words"
                body = "You have \(dueCount) \(unit) to review. \(morningBodies[dayOfYear % morningBodies.count])"
            } else {
                body = morningBodies[dayOfYear % morningBodies.count]
            }
            scheduleAt(hour: 9, minute: 0, id: Self.morningID, title: title, body: body)
        }

        if !dueWords.isEmpty {
            let picked = dueWords[dayOfYear % dueWords.count]
            scheduleAt(
                hour: 14, minute: 0,
                id: Self.afternoonID,
                title: "Do you remember?",
                body: "What does \"\(picked.word)\" mean? → \(picked.translation)"
            )
        } else if dueCount > 0 {
            let unit = dueCount == 1 ? "word" : "words"
            scheduleAt(
                hour: 14, minute: 0,
                id: Self.afternoonID,
                title: afternoonTitles[dayOfYear % afternoonTitles.count],
                body: "\(dueCount) \(unit) ready for review. A quick session keeps them fresh!"
            )
        }

        if !hasPracticedToday && currentStreak >= 2 {
            scheduleAt(
                hour: 20, minute: 0,
                id: Self.eveningID,
                title: "Don't break your streak!",
                body: "You're on a \(currentStreak)-day streak. Practice today to keep it going!"
            )
        } else if !hasPracticedToday {
            let title = eveningTitles[dayOfYear % eveningTitles.count]
            let body = eveningBodies[dayOfYear % eveningBodies.count]
            scheduleAt(hour: 20, minute: 0, id: Self.eveningID, title: title, body: body)
        }
    }

    func scheduleInactivityReminders(lastActive: Date) {
        let center = UNUserNotificationCenter.current()
        let ids = [3, 7, 14, 30].map { "\(Self.inactivityPrefix).\($0)d" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        let daysOffsets = [3, 7, 14, 30]
        for (i, d) in daysOffsets.enumerated() {
            let id = "\(Self.inactivityPrefix).\(d)d"
            let fire = Calendar.current.date(byAdding: .day, value: d, to: lastActive)
                ?? Date().addingTimeInterval(Double(d) * 86400)
            guard fire > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "We miss you!"
            content.body = inactivityBodies[i % inactivityBodies.count]
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(5, fire.timeIntervalSinceNow),
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }


    func scheduleStreakMilestone(streak: Int) {
        let milestones = [7, 30, 100, 365]
        guard milestones.contains(streak) else { return }
        guard UserDefaults.standard.bool(forKey: "notifStreakMilestones") else { return }

        let content = UNMutableNotificationContent()
        content.title = "Streak milestone!"
        content.body = "You've been learning for \(streak) days in a row. Keep going!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let id = "\(Self.streakMilestonePrefix).\(streak)"
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }

    func scheduleDailyGoalCompletion() {
        let content = UNMutableNotificationContent()
        content.title = "Daily goal reached!"
        content.body = "Awesome, you've hit your word goal for today."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: Self.dailyGoalID, content: content, trigger: trigger)
        )
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func scheduleAt(hour: Int, minute: Int, id: String, title: String, body: String) {
        let now = Date()
        let cal = Calendar.current

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        if let fireDate = cal.nextDate(after: now, matching: dateComponents, matchingPolicy: .nextTime),
           !cal.isDateInToday(fireDate) {
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
