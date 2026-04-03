import Foundation
import UserNotifications

struct NotificationPreferences {
    let globalEnabled: Bool

    let dailyReminderEnabled: Bool
    let dailyReminderHour: Int
    let dailyReminderMinute: Int

    let vocabEnabled: Bool
    let vocabShowTranscription: Bool
    let vocabShowTranslation: Bool
    let vocabIncludeMastered: Bool
    let vocabFrequency: Int
    let vocabStartHour: Int
    let vocabStartMinute: Int
    let vocabEndHour: Int
    let vocabEndMinute: Int

    let streakMilestonesEnabled: Bool

    static func fromDefaults() -> NotificationPreferences {
        let d = UserDefaults.standard
        return NotificationPreferences(
            globalEnabled: d.bool(forKey: AppStorageKeys.notifGlobalEnabled),
            dailyReminderEnabled: d.bool(forKey: AppStorageKeys.notifDailyReminderEnabled),
            dailyReminderHour: d.object(forKey: AppStorageKeys.notifDailyReminderHour) as? Int ?? 12,
            dailyReminderMinute: d.object(forKey: AppStorageKeys.notifDailyReminderMinute) as? Int ?? 0,
            vocabEnabled: d.bool(forKey: AppStorageKeys.notifVocabEnabled),
            vocabShowTranscription: d.bool(forKey: AppStorageKeys.notifVocabShowTranscription),
            vocabShowTranslation: d.bool(forKey: AppStorageKeys.notifVocabShowTranslation),
            vocabIncludeMastered: d.bool(forKey: AppStorageKeys.notifVocabIncludeMastered),
            vocabFrequency: max(1, d.integer(forKey: AppStorageKeys.notifVocabFrequency)),
            vocabStartHour: d.object(forKey: AppStorageKeys.notifVocabStartHour) as? Int ?? 9,
            vocabStartMinute: d.object(forKey: AppStorageKeys.notifVocabStartMinute) as? Int ?? 0,
            vocabEndHour: d.object(forKey: AppStorageKeys.notifVocabEndHour) as? Int ?? 18,
            vocabEndMinute: d.object(forKey: AppStorageKeys.notifVocabEndMinute) as? Int ?? 0,
            streakMilestonesEnabled: d.bool(forKey: AppStorageKeys.notifStreakMilestones)
        )
    }
}

private struct TimeSlot {
    let hour: Int
    let minute: Int
}

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

private let dailyReminderTitles = [
    String(localized: "Time to learn!"),
    String(localized: "Your daily word moment"),
    String(localized: "Keep growing!"),
    String(localized: "A word a day"),
    String(localized: "Stay curious")
]

private let dailyReminderBodies = [
    String(localized: "A few minutes now — your future self will thank you!"),
    String(localized: "Small steps, big vocabulary. Let's go!"),
    String(localized: "Your words are waiting. A quick session?"),
    String(localized: "Consistency is key. Open up and review!"),
    String(localized: "One small step today — closer to your goal.")
]

private let inactivityBodies = [
    String(localized: "It's been a while — your words are waiting!"),
    String(localized: "A quick review keeps words fresh. Come back?"),
    String(localized: "Don't let your progress fade — even 2 minutes help."),
    String(localized: "Your vocabulary misses you. Let's pick up where you left off!")
]

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private enum IDs {
        static let dailyReminder = "notif.daily.reminder"
        static let vocabPrefix = "notif.vocab."
        static let streakPrefix = "streak.milestone"
        static let dailyGoal = "daily.goal.done"
        static let inactivityPrefix = "inactive"
    }

    private static let recentWordIDsKey = "notif.recentWordIDs"

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            completion?(granted)
        }
    }

    func rescheduleAll(
        prefs: NotificationPreferences,
        allWords: [StoredWord],
        lastActiveDate: Date?
    ) {
        cancelAll()

        guard prefs.globalEnabled else { return }

        scheduleDailyReminder(prefs: prefs)
        scheduleVocabNotifications(prefs: prefs, allWords: allWords)

        if let lastActive = lastActiveDate {
            scheduleInactivityReminders(lastActive: lastActive)
        }
    }

    private func scheduleDailyReminder(prefs: NotificationPreferences) {
        guard prefs.dailyReminderEnabled else { return }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

        let content = UNMutableNotificationContent()
        content.title = dailyReminderTitles[dayOfYear % dailyReminderTitles.count]
        content.body = dailyReminderBodies[dayOfYear % dailyReminderBodies.count]
        content.sound = .default

        var components = DateComponents()
        components.hour = prefs.dailyReminderHour
        components.minute = prefs.dailyReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.dailyReminder, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleVocabNotifications(prefs: NotificationPreferences, allWords: [StoredWord]) {
        guard prefs.vocabEnabled, prefs.vocabFrequency > 0 else { return }

        let candidates = selectCandidateWords(from: allWords, includeMastered: prefs.vocabIncludeMastered)
        guard !candidates.isEmpty else { return }

        let times = distributeTimesEvenly(
            count: prefs.vocabFrequency,
            startHour: prefs.vocabStartHour,
            startMinute: prefs.vocabStartMinute,
            endHour: prefs.vocabEndHour,
            endMinute: prefs.vocabEndMinute
        )
        guard !times.isEmpty else { return }

        let daysToSchedule = min(7, 50 / prefs.vocabFrequency)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var allUsedIDs: [UUID] = []

        for dayOffset in 0..<daysToSchedule {
            guard let targetDay = cal.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let dailyWords = pickWordsAvoidingRepetition(
                candidates: candidates,
                count: prefs.vocabFrequency,
                seed: dayOffset
            )

            for (slotIndex, time) in times.enumerated() {
                guard slotIndex < dailyWords.count else { break }
                let word = dailyWords[slotIndex]

                let content = buildVocabContent(
                    word: word,
                    showTranscription: prefs.vocabShowTranscription,
                    showTranslation: prefs.vocabShowTranslation
                )

                var comps = cal.dateComponents([.year, .month, .day], from: targetDay)
                comps.hour = time.hour
                comps.minute = time.minute

                if dayOffset == 0,
                   let fireDate = cal.date(from: comps),
                   fireDate <= Date() {
                    continue
                }

                let id = "\(IDs.vocabPrefix)\(dayOffset).\(slotIndex)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)

                allUsedIDs.append(word.id)
            }
        }

        saveRecentlyUsedWordIDs(allUsedIDs)
    }

    private func buildVocabContent(
        word: StoredWord,
        showTranscription: Bool,
        showTranslation: Bool
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = word.word

        var bodyParts: [String] = []

        if showTranscription, let transcription = word.transcription, !transcription.isEmpty {
            bodyParts.append(transcription)
        }

        if showTranslation, let translation = word.translation, !translation.isEmpty {
            bodyParts.append(translation)
        }

        if bodyParts.isEmpty {
            content.body = String(localized: "Do you remember what this means?")
        } else {
            content.body = bodyParts.joined(separator: " — ")
        }

        content.sound = .default
        return content
    }

    private func selectCandidateWords(from allWords: [StoredWord], includeMastered: Bool) -> [StoredWord] {
        allWords.filter { word in
            guard let translation = word.translation, !translation.isEmpty else { return false }
            if !includeMastered {
                return word.intervalDays < 21
            }
            return true
        }
    }

    private func pickWordsAvoidingRepetition(
        candidates: [StoredWord],
        count: Int,
        seed: Int = 0
    ) -> [StoredWord] {
        let recentIDs = loadRecentlyUsedWordIDs()
        let today = Calendar.current.startOfDay(for: Date())

        let fresh = candidates.filter { !recentIDs.contains($0.id) }
        let stale = candidates.filter { recentIDs.contains($0.id) }

        let dueFresh = fresh.filter { ($0.dueDate ?? .distantPast) <= today }
        let otherFresh = fresh.filter { ($0.dueDate ?? .distantPast) > today }
        let dueStale = stale.filter { ($0.dueDate ?? .distantPast) <= today }
        let otherStale = stale.filter { ($0.dueDate ?? .distantPast) > today }

        let daySeed = UInt64(Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 1) + UInt64(seed)
        var rng = SeededRNG(seed: daySeed)

        var pool: [StoredWord] = []
        pool.append(contentsOf: dueFresh.shuffled(using: &rng))
        pool.append(contentsOf: otherFresh.shuffled(using: &rng))
        pool.append(contentsOf: dueStale.shuffled(using: &rng))
        pool.append(contentsOf: otherStale.shuffled(using: &rng))

        return Array(pool.prefix(count))
    }

    private func saveRecentlyUsedWordIDs(_ ids: [UUID]) {
        let strings = ids.map { $0.uuidString }
        let existing = UserDefaults.standard.stringArray(forKey: Self.recentWordIDsKey) ?? []
        let merged = Array((strings + existing).prefix(50))
        UserDefaults.standard.set(merged, forKey: Self.recentWordIDsKey)
    }

    private func loadRecentlyUsedWordIDs() -> Set<UUID> {
        let strings = UserDefaults.standard.stringArray(forKey: Self.recentWordIDsKey) ?? []
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }

    private func distributeTimesEvenly(
        count: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> [TimeSlot] {
        let startMins = startHour * 60 + startMinute
        let endMins = endHour * 60 + endMinute
        let totalRange = endMins - startMins

        guard count > 0, totalRange > 0 else { return [] }

        let intervalSize = Double(totalRange) / Double(count)

        let daySeed = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        var rng = SeededRNG(seed: UInt64(daySeed + 999))

        var slots: [TimeSlot] = []
        for i in 0..<count {
            let intervalStart = Double(startMins) + Double(i) * intervalSize
            let intervalEnd = intervalStart + intervalSize

            let midpoint = (intervalStart + intervalEnd) / 2.0
            let jitterRange = intervalSize * 0.25
            let jitter = Double(rng.next() % 1000) / 1000.0 * jitterRange * 2.0 - jitterRange

            let minuteOfDay = Int(max(Double(startMins), min(Double(endMins), midpoint + jitter)))

            slots.append(TimeSlot(hour: minuteOfDay / 60, minute: minuteOfDay % 60))
        }

        return slots
    }

    func scheduleInactivityReminders(lastActive: Date) {
        let center = UNUserNotificationCenter.current()
        let daysOffsets = [3, 7, 14, 30]
        let ids = daysOffsets.map { "\(IDs.inactivityPrefix).\($0)d" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for (i, d) in daysOffsets.enumerated() {
            let id = "\(IDs.inactivityPrefix).\(d)d"
            let fire = Calendar.current.date(byAdding: .day, value: d, to: lastActive)
                ?? Date().addingTimeInterval(Double(d) * 86400)
            guard fire > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "We miss you!")
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
        guard UserDefaults.standard.bool(forKey: AppStorageKeys.notifGlobalEnabled) else { return }
        guard UserDefaults.standard.bool(forKey: AppStorageKeys.notifStreakMilestones) else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Streak milestone!")
        content.body = String(localized: "You've been learning for \(streak) days in a row. Keep going!")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let id = "\(IDs.streakPrefix).\(streak)"
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }

    func scheduleDailyGoalCompletion() {
        guard UserDefaults.standard.bool(forKey: AppStorageKeys.notifGlobalEnabled) else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Daily goal reached!")
        content.body = String(localized: "Awesome, you've hit your word goal for today.")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: IDs.dailyGoal, content: content, trigger: trigger)
        )
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
