import SwiftUI

struct StreakCalendarView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage("currentStreak") private var currentStreak: Int = 0

    private let weeksToShow = 13
    private let daysInWeek = 7

    private var calendarData: [[DayActivity]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Group words by day
        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }

        // Find the start of the grid (Sunday of weeksToShow weeks ago)
        let todayWeekday = cal.component(.weekday, from: today) // 1=Sun, 7=Sat
        let daysBack = (weeksToShow - 1) * 7 + (todayWeekday - 1)
        guard let startDate = cal.date(byAdding: .day, value: -daysBack, to: today) else { return [] }

        var weeks: [[DayActivity]] = []
        var currentDate = startDate

        for _ in 0..<weeksToShow {
            var week: [DayActivity] = []
            for _ in 0..<daysInWeek {
                let count = grouped[currentDate]?.count ?? 0
                let isFuture = currentDate > today
                week.append(DayActivity(date: currentDate, count: count, isFuture: isFuture, isToday: currentDate == today))
                currentDate = cal.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            weeks.append(week)
        }

        return weeks
    }

    private var maxCount: Int {
        let allCounts = calendarData.flatMap { $0.map(\.count) }
        return max(allCounts.max() ?? 1, 1)
    }

    private func cellColor(for activity: DayActivity) -> Color {
        if activity.isFuture { return Color.clear }
        if activity.count == 0 { return Color.mainGrey.opacity(0.1) }

        let intensity = min(1.0, Double(activity.count) / Double(max(maxCount, 3)))
        let baseColor = themeStore.accentGreen
        return baseColor.opacity(0.25 + intensity * 0.75)
    }

    private var monthLabels: [(String, Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let todayWeekday = cal.component(.weekday, from: today)
        let daysBack = (weeksToShow - 1) * 7 + (todayWeekday - 1)
        guard let startDate = cal.date(byAdding: .day, value: -daysBack, to: today) else { return [] }

        let df = DateFormatter()
        df.dateFormat = "MMM"

        var labels: [(String, Int)] = []
        var lastMonth = -1

        for weekIndex in 0..<weeksToShow {
            guard let weekStart = cal.date(byAdding: .day, value: weekIndex * 7, to: startDate) else { continue }
            let month = cal.component(.month, from: weekStart)
            if month != lastMonth {
                labels.append((df.string(from: weekStart), weekIndex))
                lastMonth = month
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeStore.accentGold)
                Text("\(currentStreak) day streak")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.mainBlack)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                // Month labels
                GeometryReader { geo in
                    let cellSize = (geo.size.width - CGFloat(weeksToShow - 1) * 3) / CGFloat(weeksToShow)
                    HStack(spacing: 0) {
                        ForEach(monthLabels, id: \.1) { label, weekIndex in
                            Text(label)
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundColor(.mainGrey)
                                .position(
                                    x: CGFloat(weekIndex) * (cellSize + 3) + cellSize / 2,
                                    y: 6
                                )
                        }
                    }
                }
                .frame(height: 14)

                // Calendar grid
                GeometryReader { geo in
                    let cellSize = (geo.size.width - CGFloat(weeksToShow - 1) * 3) / CGFloat(weeksToShow)
                    HStack(alignment: .top, spacing: 3) {
                        ForEach(Array(calendarData.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 3) {
                                ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(cellColor(for: day))
                                        .frame(width: cellSize, height: cellSize)
                                        .overlay(
                                            day.isToday
                                                ? RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                    .stroke(Color.mainBlack.opacity(0.4), lineWidth: 1)
                                                : nil
                                        )
                                }
                            }
                        }
                    }
                }
                .aspectRatio(CGFloat(weeksToShow) / CGFloat(daysInWeek), contentMode: .fit)
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(.mainGrey)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(intensity == 0 ? Color.mainGrey.opacity(0.1) : themeStore.accentGreen.opacity(0.25 + intensity * 0.75))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(.mainGrey)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.divider, lineWidth: 1)
                )
        )
    }
}

private struct DayActivity {
    let date: Date
    let count: Int
    let isFuture: Bool
    let isToday: Bool
}

#Preview {
    StreakCalendarView()
        .environmentObject(WordsStore())
        .environmentObject(ThemeStore())
        .padding()
}
