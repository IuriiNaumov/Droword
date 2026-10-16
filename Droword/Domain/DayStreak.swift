import Foundation

enum DayStreak {
    static let freezesPerWeek = 2
    static let freezeWindowDays = 7

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
        usedFreezeDays: Set<Date>,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> (streak: Int, coveredDays: Set<Date>, newFreezes: Set<Date>) {
        let activity = Set(activityDays.map { calendar.startOfDay(for: $0) })
        let used = Set(usedFreezeDays.map { calendar.startOfDay(for: $0) }).subtracting(activity)
        let start = calendar.startOfDay(for: today)

        var streak = 0
        var day = start
        var covered: Set<Date> = []
        var newFreezes: Set<Date> = []

        if !activity.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else {
                return (0, [], [])
            }
            day = yesterday
        }

        while true {
            if activity.contains(day) {
                streak += 1
                covered.insert(day)
            } else if let gap = bridgeGap(
                from: day,
                activity: activity,
                used: used,
                fresh: newFreezes,
                calendar: calendar
            ) {
                for missed in gap {
                    streak += 1
                    covered.insert(missed)
                    if !used.contains(missed) {
                        newFreezes.insert(missed)
                    }
                }
                day = gap.last ?? day
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        return (streak, covered, newFreezes)
    }

    private static func bridgeGap(
        from day: Date,
        activity: Set<Date>,
        used: Set<Date>,
        fresh: Set<Date>,
        calendar: Calendar
    ) -> [Date]? {
        var gap: [Date] = []
        var simulated = fresh
        var cursor = day

        while !activity.contains(cursor) {
            if used.contains(cursor) {
                gap.append(cursor)
            } else {
                let newCount = gap.filter { !used.contains($0) }.count
                if newCount >= freezesPerWeek { break }
                if freezesNear(cursor, used: used, simulated: simulated, calendar: calendar) >= freezesPerWeek {
                    break
                }
                simulated.insert(cursor)
                gap.append(cursor)
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
            if gap.count > freezeWindowDays { break }
        }

        if activity.contains(cursor) {
            return gap.isEmpty ? nil : gap
        }
        let storedPrefix = Array(gap.prefix { used.contains($0) })
        return storedPrefix.isEmpty ? nil : storedPrefix
    }

    private static func freezesNear(
        _ day: Date,
        used: Set<Date>,
        simulated: Set<Date>,
        calendar: Calendar
    ) -> Int {
        let limit = freezeWindowDays - 1
        return used.union(simulated).filter { freeze in
            let days = calendar.dateComponents([.day], from: freeze, to: day).day ?? limit + 1
            return abs(days) <= limit
        }.count
    }
}
