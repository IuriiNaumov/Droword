import SwiftUI

private struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let isFuture: Bool
    let isToday: Bool
    let studyMinutes: Int
    let words: [String]
    let isStreakMilestone: Bool
}

private struct CalendarStats {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalActiveDays: Int = 0
    var bestDay: (date: Date, count: Int)? = nil
}

private struct MonthData {
    let year: Int
    let month: Int
    let title: String
    let weekRows: [[DayActivity?]]
    let perfectWeeks: Set<Int>
}

struct StreakCalendarView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var studyTimeTracker: StudyTimeTracker
    @ObservedObject private var activity = StudyActivityStore.shared
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    private let daysInWeek = 7

    @State private var selectedDay: DayActivity? = nil
    @State private var cachedStats = CalendarStats()
    @State private var cachedMaxCount: Int = 1
    @State private var cachedMilestones: Set<Date> = []
    @State private var currentStreakDates: Set<Date> = []

    @State private var displayedMonth: Date = Date()
    @State private var cachedMonthData: MonthData? = nil
    @State private var cachedEarliestDate: Date? = nil

    private static let weekdaySymbols: [String] = {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            statsRow

            if let day = selectedDay, !day.isFuture {
                selectedDayCard(day: day)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            monthCalendarView
        }
        .onAppear {
            rebuildEarliestDate()
            rebuildMilestones()
            rebuildCurrentStreakDates()
            rebuildMonthCalendar()
            rebuildStats()
        }
        .onChange(of: activity.dayKeys) {
            rebuildEarliestDate()
            rebuildMilestones()
            rebuildCurrentStreakDates()
            rebuildMonthCalendar()
            rebuildStats()
        }
        .onChange(of: store.words.count) {
            rebuildEarliestDate()
            rebuildMilestones()
            rebuildCurrentStreakDates()
            rebuildMonthCalendar()
            rebuildStats()
        }
        .onChange(of: displayedMonth) {
            rebuildMonthCalendar()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBubble(value: "\(cachedStats.currentStreak)", label: "Streak", fire: true)
            statBubble(value: "\(cachedStats.longestStreak)", label: "Best streak")
            statBubble(value: "\(cachedStats.totalActiveDays)", label: "Active days")
            if let best = cachedStats.bestDay {
                statBubble(value: "\(best.count)", label: "Best day")
            }
        }
    }

    private func statBubble(value: String, label: LocalizedStringKey, fire: Bool = false) -> some View {
        VStack(spacing: 2) {
            if fire {
                HStack(spacing: 4) {
                    BurningFlameIcon(size: 14)
                    Text(value)
                        .font(themeStore.bold(18))
                        .foregroundStyle(StreakFireStyle.red)
                }
            } else {
                Text(value)
                    .font(themeStore.bold(18))
                    .foregroundStyle(themeStore.mainText)
            }
            Text(label)
                .font(themeStore.regular(11))
                .foregroundStyle(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var monthCalendarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            monthNavigationHeader
            weekdayHeaderRow

            if let data = cachedMonthData {
                monthDayGrid(data: data)
            }
        }
    }

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                Haptics.selection()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = prev
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canGoBack ? themeStore.mainAccentColor : themeStore.mainAccentColor.opacity(0.25))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(!canGoBack)

            Spacer()

            Text(cachedMonthData?.title ?? "")
                .font(themeStore.bold(17))
                .foregroundStyle(themeStore.mainText)

            Spacer()

            Button {
                Haptics.selection()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = next
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canGoForward ? themeStore.mainAccentColor : themeStore.mainAccentColor.opacity(0.25))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(!canGoForward)
        }
    }

    private var canGoBack: Bool {
        guard let earliest = cachedEarliestDate else { return false }
        let cal = Calendar.current
        let earliestMonth = cal.dateInterval(of: .month, for: earliest)?.start ?? earliest
        let currentDisplayStart = cal.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        return currentDisplayStart > earliestMonth
    }

    private var canGoForward: Bool {
        let cal = Calendar.current
        let currentMonthStart = cal.dateInterval(of: .month, for: Date())?.start ?? Date()
        let displayStart = cal.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        return displayStart < currentMonthStart
    }

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(Self.weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(themeStore.regular(11))
                    .foregroundStyle(themeStore.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func monthDayGrid(data: MonthData) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<data.weekRows.count, id: \.self) { rowIndex in
                let weekRow = data.weekRows[rowIndex]
                let isPerfect = data.perfectWeeks.contains(rowIndex)

                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { colIndex in
                        if let day = weekRow[colIndex] {
                            monthDayCell(day: day)
                                .frame(maxWidth: .infinity)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
                .background(
                    isPerfect ?
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(themeStore.accentGold.opacity(0.1))
                        : nil
                )
            }
        }
    }

    private func monthDayCell(day: DayActivity) -> some View {
        let dayNum = Calendar.current.component(.day, from: day.date)
        let isSelected = selectedDay?.date == day.date

        return VStack(spacing: 1) {
            ZStack {
                Circle()
                    .fill(monthCellColor(for: day))
                    .frame(width: isSelected ? 38 : 34, height: isSelected ? 38 : 34)

                Text("\(dayNum)")
                    .font(themeStore.medium(13))
                    .foregroundStyle(day.isFuture
                        ? themeStore.secondaryText.opacity(0.3)
                        : themeStore.mainText)
            }

            if day.isStreakMilestone {
                Text("⭐")
                    .font(.system(size: 8))
                    .frame(height: 10)
            } else if !day.isFuture && day.count > 0 && currentStreakDates.contains(day.date) {
                Text("🔥")
                    .font(.system(size: 8))
                    .frame(height: 10)
            } else {
                Color.clear.frame(height: 10)
            }
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !day.isFuture else { return }
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedDay?.date == day.date {
                    selectedDay = nil
                } else {
                    selectedDay = day
                }
            }
        }
    }

    private func monthCellColor(for day: DayActivity) -> Color {
        if day.isFuture { return Color.clear }
        if day.count == 0 { return themeStore.secondaryText.opacity(0.08) }
        let intensity = min(1.0, Double(day.count) / Double(max(cachedMaxCount, 3)))
        if currentStreakDates.contains(day.date) {
            return StreakFireStyle.red.opacity(0.35 + intensity * 0.55)
        }
        return themeStore.accentGreen.opacity(0.3 + intensity * 0.7)
    }

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private static let selectedDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    private func selectedDayCard(day: DayActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Self.selectedDayFormatter.string(from: day.date))
                    .font(themeStore.medium(14))
                    .foregroundStyle(themeStore.mainText)
                Spacer()
                if day.isToday {
                    Text("Today")
                        .font(themeStore.medium(12))
                        .foregroundStyle(themeStore.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(themeStore.secondaryText.opacity(0.1))
                        )
                }
            }

            HStack(spacing: 12) {
                if !day.words.isEmpty {
                    Label {
                        Text("\(day.count) words")
                    } icon: {
                        Image(systemName: "text.book.closed")
                    }
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.mainText)
                }
                if StudyActivityStore.shared.studied(on: day.date) {
                    Label {
                        Text("Studied")
                    } icon: {
                        Image(systemName: "bolt.fill")
                    }
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.mainText)
                }
                if day.studyMinutes > 0 {
                    Label {
                        Text("\(day.studyMinutes)m studied")
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.mainText)
                }
                if day.words.isEmpty && day.studyMinutes == 0 && !StudyActivityStore.shared.studied(on: day.date) {
                    Text("No activity")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
            }

        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 12))
    }

    private func rebuildEarliestDate() {
        StudyActivityStore.shared.ensureMigrated(from: store.words)
        let wordMin = store.words.lazy.map(\.dateAdded).min()
        let studyMin = StudyActivityStore.shared.activityDates().min()
        cachedEarliestDate = [wordMin, studyMin].compactMap { $0 }.min()
    }

    private func rebuildMonthCalendar() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let year = cal.component(.year, from: displayedMonth)
        let month = cal.component(.month, from: displayedMonth)

        guard let firstOfMonth = cal.date(from: DateComponents(year: year, month: month, day: 1)),
              let daysRange = cal.range(of: .day, in: .month, for: firstOfMonth) else { return }

        let daysInMonth = daysRange.count

        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let dayOffset = (firstWeekday + 5) % 7

        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }

        let lastOfMonth = cal.date(byAdding: .day, value: daysInMonth - 1, to: firstOfMonth) ?? firstOfMonth
        let studyMinutes = studyTimeTracker.minutesForDateRange(from: firstOfMonth, to: lastOfMonth)

        var allDays: [DayActivity] = []
        var maxCount = 0
        for dayNum in 1...daysInMonth {
            guard let date = cal.date(from: DateComponents(year: year, month: month, day: dayNum)) else { continue }
            let startOfDate = cal.startOfDay(for: date)
            let wordsForDay = grouped[startOfDate] ?? []
            let wordNames = Array(wordsForDay.prefix(5).map { $0.word })
            let isFuture = startOfDate > today
            let studied = StudyActivityStore.shared.studied(on: startOfDate)
            let count = max(wordsForDay.count, studied ? 1 : 0)
            if count > maxCount { maxCount = count }

            allDays.append(DayActivity(
                date: startOfDate,
                count: count,
                isFuture: isFuture,
                isToday: startOfDate == today,
                studyMinutes: studyMinutes[startOfDate] ?? 0,
                words: wordNames,
                isStreakMilestone: cachedMilestones.contains(startOfDate)
            ))
        }

        cachedMaxCount = max(maxCount, 1)

        var weekRows: [[DayActivity?]] = []
        var currentRow: [DayActivity?] = Array(repeating: nil, count: dayOffset)
        for day in allDays {
            currentRow.append(day)
            if currentRow.count == 7 {
                weekRows.append(currentRow)
                currentRow = []
            }
        }
        if !currentRow.isEmpty {
            while currentRow.count < 7 { currentRow.append(nil) }
            weekRows.append(currentRow)
        }

        var perfectWeeks: Set<Int> = []
        for (index, row) in weekRows.enumerated() {
            let nonNilDays = row.compactMap { $0 }
            if nonNilDays.count == 7 && nonNilDays.allSatisfy({ $0.count > 0 && !$0.isFuture }) {
                perfectWeeks.insert(index)
            }
        }

        let title = Self.monthTitleFormatter.string(from: firstOfMonth)

        cachedMonthData = MonthData(
            year: year, month: month, title: title,
            weekRows: weekRows, perfectWeeks: perfectWeeks
        )
    }

    private func rebuildStats() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }
        let studyDates = WordsStore.activityDays(from: store.words)

        var stats = CalendarStats()

        let rangeStart: Date
        if let md = cachedMonthData {
            rangeStart = cal.date(from: DateComponents(year: md.year, month: md.month, day: 1)) ?? today
        } else {
            rangeStart = today
        }

        let rangeGrouped = grouped.filter { $0.key >= rangeStart && $0.key <= today }
        let activeDates = Set(rangeGrouped.keys.filter { (rangeGrouped[$0]?.count ?? 0) > 0 }).union(
            studyDates.filter { $0 >= rangeStart && $0 <= today }
        )
        stats.totalActiveDays = activeDates.count

        if isPremium {
            stats.currentStreak = WordsStore.computeCurrentStreakWithFreeze(from: store.words).streak
        } else {
            stats.currentStreak = WordsStore.computeCurrentStreak(from: store.words)
        }

        let sortedDates = activeDates.sorted()
        var longest = 0
        var current = 0
        var expectedDate: Date? = nil
        for date in sortedDates {
            if let expected = expectedDate, date == expected {
                current += 1
            } else {
                current = 1
            }
            if current > longest { longest = current }
            expectedDate = cal.date(byAdding: .day, value: 1, to: date)
        }
        stats.longestStreak = longest

        if let best = rangeGrouped.max(by: { $0.value.count < $1.value.count }) {
            stats.bestDay = (best.key, best.value.count)
        }

        cachedStats = stats
    }

    private func rebuildMilestones() {
        let cal = Calendar.current
        let allDates = WordsStore.activityDays(from: store.words).sorted()
        let thresholds: Set<Int> = [7, 30, 100, 365]
        var milestones: Set<Date> = []

        var streakLength = 0
        var expectedDate: Date? = nil

        for date in allDates {
            if let expected = expectedDate, date == expected {
                streakLength += 1
            } else {
                streakLength = 1
            }
            if thresholds.contains(streakLength) {
                milestones.insert(date)
            }
            expectedDate = cal.date(byAdding: .day, value: 1, to: date)
        }
        cachedMilestones = milestones
    }

    private func rebuildCurrentStreakDates() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let allDates = WordsStore.activityDays(from: store.words)
        var dates: Set<Date> = []
        var day = today
        var usedFreeze = false

        while true {
            if allDates.contains(day) {
                dates.insert(day)
            } else if isPremium && !usedFreeze && day != today {

                dates.insert(day)
                usedFreeze = true
            } else {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        currentStreakDates = dates
    }
}

#Preview {
    StreakCalendarView()
        .environmentObject(WordsStore())
        .environmentObject(ThemeStore())
        .environmentObject(StudyTimeTracker.shared)
        .padding()
}
