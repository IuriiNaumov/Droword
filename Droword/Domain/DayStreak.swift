import Foundation

enum DayStreak {
    static func current(
        activityDays: Set<Date>,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: today)
        var day = start
        if !activityDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while activityDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    static func currentWithFreeze(
        activityDays: Set<Date>,
        lastFreezeDay: Date?,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> (streak: Int, freezeDate: Date?) {
        let start = calendar.startOfDay(for: today)
        var streak = 0
        var day = start
        var freezeDate: Date? = nil

        if !activityDays.contains(day) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
                day = yesterday
            }
        }

        while true {
            if activityDays.contains(day) {
                streak += 1
            } else if freezeDate == nil {
                let canFreeze: Bool
                if let lastFreeze = lastFreezeDay {
                    let daysSinceFreeze = calendar.dateComponents([.day], from: lastFreeze, to: day).day ?? 0
                    canFreeze = abs(daysSinceFreeze) >= 7
                } else {
                    canFreeze = true
                }
                if canFreeze && day != start {
                    freezeDate = day
                    streak += 1
                } else {
                    break
                }
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return (streak, freezeDate)
    }
}
