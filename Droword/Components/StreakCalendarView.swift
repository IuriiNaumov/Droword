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
        return Array(symbols[1...]) + [symbols[0]]  // Mon–Sun order
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
            statBubble(value: "\(cachedStats.currentStreak)", label: "Streak")
            statBubble(value: "\(cachedStats.longestStreak)", label: "Best streak")
            statBubble(value: "\(cachedStats.totalActiveDays)", label: "Active days")
            if let best = cachedStats.bestDay {
                statBubble(value: "\(best.count)", label: "Best day")
            }
        }
    }

    private func statBubble(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoBack ? themeStore.mainText : themeStore.secondaryText.opacity(0.3))
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoForward ? themeStore.mainText : themeStore.secondaryText.opacity(0.3))
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
                    .frame(width: 34, height: 34)

                if day.isToday {
                    Circle()
                        .stroke(themeStore.mainText, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }

                if isSelected {
                    Circle()
                        .stroke(themeStore.mainText, lineWidth: 2)
                        .frame(width: 38, height: 38)
                }

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
                if day.count > 0 {
                    Label {
                        Text("\(day.count) words")
                    } icon: {
                        Image(systemName: "text.book.closed")
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
                if day.count == 0 && day.studyMinutes == 0 {
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
        cachedEarliestDate = store.words.lazy.map(\.dateAdded).min()
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
            let count = wordsForDay.count
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

        var stats = CalendarStats()

        let rangeStart: Date
        if let md = cachedMonthData {
            rangeStart = cal.date(from: DateComponents(year: md.year, month: md.month, day: 1)) ?? today
        } else {
            rangeStart = today
        }

        let rangeGrouped = grouped.filter { $0.key >= rangeStart && $0.key <= today }
        let activeDates = Set(rangeGrouped.keys.filter { (rangeGrouped[$0]?.count ?? 0) > 0 })
        stats.totalActiveDays = activeDates.count

        if isPremium {
            let result = WordsStore.computeCurrentStreakWithFreeze(from: store.words)
            stats.currentStreak = result.streak
        } else {
            let allActiveDates = Set(grouped.keys.filter { (grouped[$0]?.count ?? 0) > 0 })
            var day = today
            var streak = 0
            while allActiveDates.contains(day) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            }
            stats.currentStreak = streak
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
        let allDates = Set(store.words.map { cal.startOfDay(for: $0.dateAdded) }).sorted()
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
        let allDates = Set(store.words.map { cal.startOfDay(for: $0.dateAdded) })
        var dates: Set<Date> = []
        var day = today
        var usedFreeze = false

        while true {
            if allDates.contains(day) {
                dates.insert(day)
            } else if isPremium && !usedFreeze && day != today {
                // Allow one freeze gap in the visual streak
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
