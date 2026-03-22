import SwiftUI

// MARK: - Enums

enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case heatmap = "Heatmap"
}

enum CalendarTimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case year = "Year"
    case all = "All"

    var id: String { rawValue }

    var weeksToShow: Int {
        switch self {
        case .week: return 1
        case .month: return 5
        case .threeMonths: return 13
        case .sixMonths: return 26
        case .year: return 52
        case .all: return 0
        }
    }
}

// MARK: - Models

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

// MARK: - StreakCalendarView

struct StreakCalendarView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var studyTimeTracker: StudyTimeTracker

    private let daysInWeek = 7

    // Mode
    @State private var selectedMode: CalendarViewMode = .month

    // Shared
    @State private var selectedDay: DayActivity? = nil
    @State private var cachedStats = CalendarStats()
    @State private var cachedMaxCount: Int = 1
    @State private var cachedMilestones: Set<Date> = []
    @State private var currentStreakDates: Set<Date> = []

    // Month mode
    @State private var displayedMonth: Date = Date()
    @State private var cachedMonthData: MonthData? = nil

    // Heatmap mode
    @State private var selectedRange: CalendarTimeRange = .threeMonths
    @State private var cachedCalendar: [[DayActivity]] = []
    @State private var cachedMonthLabels: [(String, Int)] = []

    private let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Mode toggle
            modeToggle

            // Stats row
            statsRow

            // Selected day detail card
            if let day = selectedDay, !day.isFuture {
                selectedDayCard(day: day)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Calendar content
            if selectedMode == .month {
                monthCalendarView
            } else {
                heatmapCalendarView
            }
        }
        .onAppear {
            rebuildMilestones()
            rebuildCurrentStreakDates()
            if selectedMode == .month {
                rebuildMonthCalendar()
            } else {
                rebuildHeatmap()
            }
            rebuildStats()
        }
        .onChange(of: store.words.count) {
            rebuildMilestones()
            rebuildCurrentStreakDates()
            if selectedMode == .month {
                rebuildMonthCalendar()
            } else {
                rebuildHeatmap()
            }
            rebuildStats()
        }
        .onChange(of: selectedRange) {
            rebuildHeatmap()
            rebuildStats()
        }
        .onChange(of: displayedMonth) {
            rebuildMonthCalendar()
        }
        .onChange(of: selectedMode) {
            selectedDay = nil
            if selectedMode == .month {
                rebuildMonthCalendar()
            } else {
                rebuildHeatmap()
                rebuildStats()
            }
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 8) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Button {
                    Haptics.selection()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(selectedMode == mode ? themeStore.cardBg : themeStore.mainText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedMode == mode ? themeStore.mainText : themeStore.secondaryText.opacity(0.1))
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - Stats Row

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

    private func statBubble(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(themeStore.mainText)
            Text(label)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Month Calendar View

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
                    .foregroundColor(canGoBack ? themeStore.mainText : themeStore.secondaryText.opacity(0.3))
            }
            .disabled(!canGoBack)

            Spacer()

            Text(cachedMonthData?.title ?? "")
                .font(.custom("Poppins-Bold", size: 17))
                .foregroundColor(themeStore.mainText)

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
                    .foregroundColor(canGoForward ? themeStore.mainText : themeStore.secondaryText.opacity(0.3))
            }
            .disabled(!canGoForward)
        }
    }

    private var canGoBack: Bool {
        guard let earliest = store.words.map({ $0.dateAdded }).min() else { return false }
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
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(themeStore.secondaryText)
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
                // Activity circle
                Circle()
                    .fill(monthCellColor(for: day))
                    .frame(width: 34, height: 34)

                // Today ring
                if day.isToday {
                    Circle()
                        .stroke(themeStore.mainText, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }

                // Selected ring
                if isSelected {
                    Circle()
                        .stroke(themeStore.accentGreen, lineWidth: 2)
                        .frame(width: 38, height: 38)
                }

                // Day number
                Text("\(dayNum)")
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(day.isFuture
                        ? themeStore.secondaryText.opacity(0.3)
                        : day.count > 0
                            ? .white
                            : themeStore.mainText)
            }

            // Streak / milestone indicator
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

    // MARK: - Heatmap Calendar View

    private var heatmapCalendarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time range picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CalendarTimeRange.allCases) { range in
                        Button {
                            Haptics.selection()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedRange = range
                                selectedDay = nil
                            }
                        } label: {
                            Text(range.rawValue)
                                .font(.custom("Poppins-Medium", size: 13))
                                .foregroundColor(selectedRange == range ? themeStore.cardBg : themeStore.mainText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedRange == range ? themeStore.mainText : themeStore.secondaryText.opacity(0.1))
                                )
                        }
                    }
                }
            }

            heatmapGrid
            heatmapLegend
        }
    }

    private let heatmapDayLabelWidth: CGFloat = 32

    private var heatmapGrid: some View {
        let weeks = effectiveWeeksToShow

        return VStack(alignment: .leading, spacing: 2) {
            // Month labels
            HStack(spacing: 0) {
                Color.clear.frame(width: heatmapDayLabelWidth, height: 14)

                GeometryReader { geo in
                    let cellSize = (geo.size.width - CGFloat(weeks - 1) * 3) / CGFloat(max(weeks, 1))
                    ForEach(cachedMonthLabels, id: \.1) { label, weekIndex in
                        Text(label)
                            .font(.custom("Poppins-Regular", size: 10))
                            .foregroundColor(themeStore.secondaryText)
                            .position(
                                x: CGFloat(weekIndex) * (cellSize + 3) + cellSize / 2,
                                y: 6
                            )
                    }
                }
            }
            .frame(height: 14)

            // Grid with day labels
            HStack(alignment: .top, spacing: 0) {
                // Day-of-week labels (all 7)
                VStack(spacing: 3) {
                    ForEach(0..<daysInWeek, id: \.self) { index in
                        GeometryReader { geo in
                            Text(weekdaySymbols[index])
                                .font(.custom("Poppins-Regular", size: 9))
                                .foregroundColor(themeStore.secondaryText)
                                .frame(width: heatmapDayLabelWidth, alignment: .trailing)
                                .position(x: heatmapDayLabelWidth / 2, y: geo.size.height / 2)
                        }
                    }
                }
                .frame(width: heatmapDayLabelWidth)

                // Heatmap cells
                GeometryReader { geo in
                    let cellSize = (geo.size.width - CGFloat(weeks - 1) * 3) / CGFloat(max(weeks, 1))
                    HStack(alignment: .top, spacing: 3) {
                        ForEach(Array(cachedCalendar.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 3) {
                                ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(heatmapCellColor(for: day))
                                            .frame(width: cellSize, height: cellSize)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                    .stroke(heatmapBorderColor(for: day), lineWidth: heatmapBorderWidth(for: day))
                                            )

                                        // Milestone gold dot
                                        if day.isStreakMilestone {
                                            Circle()
                                                .fill(themeStore.accentGold)
                                                .frame(width: 4, height: 4)
                                                .offset(x: cellSize / 2 - 3, y: -cellSize / 2 + 3)
                                        }
                                    }
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
                            }
                        }
                    }
                }
                .aspectRatio(CGFloat(max(weeks, 1)) / CGFloat(daysInWeek), contentMode: .fit)
            }
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 4) {
            Text("0")
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(themeStore.secondaryText)
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(intensity == 0 ? themeStore.secondaryText.opacity(0.1) : themeStore.accentGreen.opacity(0.25 + intensity * 0.75))
                    .frame(width: 12, height: 12)
            }
            Text("\(cachedMaxCount)+")
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(themeStore.secondaryText)
        }
    }

    private func heatmapCellColor(for day: DayActivity) -> Color {
        if day.isFuture { return Color.clear }
        if day.count == 0 { return themeStore.secondaryText.opacity(0.1) }
        let intensity = min(1.0, Double(day.count) / Double(max(cachedMaxCount, 3)))
        return themeStore.accentGreen.opacity(0.25 + intensity * 0.75)
    }

    private func heatmapBorderColor(for day: DayActivity) -> Color {
        if selectedDay?.date == day.date { return themeStore.mainText }
        if day.isToday { return themeStore.mainText.opacity(0.4) }
        return Color.clear
    }

    private func heatmapBorderWidth(for day: DayActivity) -> CGFloat {
        if selectedDay?.date == day.date { return 1.5 }
        if day.isToday { return 1 }
        return 0
    }

    // MARK: - Selected Day Card (Enriched)

    private static let selectedDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    private func selectedDayCard(day: DayActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Date + Today badge
            HStack {
                Text(Self.selectedDayFormatter.string(from: day.date))
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(themeStore.mainText)
                Spacer()
                if day.isToday {
                    Text("Today")
                        .font(.custom("Poppins-Medium", size: 12))
                        .foregroundColor(themeStore.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(themeStore.secondaryText.opacity(0.1))
                        )
                }
            }

            // Stats chips
            HStack(spacing: 12) {
                if day.count > 0 {
                    Label("\(day.count) \(day.count == 1 ? "word" : "words")", systemImage: "text.book.closed")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.mainText)
                }
                if day.studyMinutes > 0 {
                    Label("\(day.studyMinutes)m studied", systemImage: "clock")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.mainText)
                }
                if day.count == 0 && day.studyMinutes == 0 {
                    Text("No activity")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.secondaryText)
                }
            }

            // Word list
            if !day.words.isEmpty {
                Divider()
                    .background(themeStore.dividerColor)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(day.words, id: \.self) { word in
                        Text(word)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(themeStore.secondaryText)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeStore.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
                )
        )
    }

    // MARK: - Data Building

    private var effectiveWeeksToShow: Int {
        if selectedRange == .all {
            guard let earliest = store.words.map({ $0.dateAdded }).min() else { return 1 }
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let start = cal.startOfDay(for: earliest)
            let days = max(1, (cal.dateComponents([.day], from: start, to: today).day ?? 0) + 1)
            return max(1, Int(ceil(Double(days) / 7.0)) + 1)
        }
        return selectedRange.weeksToShow
    }

    private func rebuildMonthCalendar() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let year = cal.component(.year, from: displayedMonth)
        let month = cal.component(.month, from: displayedMonth)

        guard let firstOfMonth = cal.date(from: DateComponents(year: year, month: month, day: 1)),
              let daysRange = cal.range(of: .day, in: .month, for: firstOfMonth) else { return }

        let daysInMonth = daysRange.count

        // Weekday of first: convert to Mon=0 ... Sun=6
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let dayOffset = (firstWeekday + 5) % 7

        // Group words by day
        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }

        // Study minutes
        let lastOfMonth = cal.date(byAdding: .day, value: daysInMonth - 1, to: firstOfMonth) ?? firstOfMonth
        let studyMinutes = studyTimeTracker.minutesForDateRange(from: firstOfMonth, to: lastOfMonth)

        // Build days
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

        // Build week rows
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

        // Perfect weeks
        var perfectWeeks: Set<Int> = []
        for (index, row) in weekRows.enumerated() {
            let nonNilDays = row.compactMap { $0 }
            if nonNilDays.count == 7 && nonNilDays.allSatisfy({ $0.count > 0 && !$0.isFuture }) {
                perfectWeeks.insert(index)
            }
        }

        // Title
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        let title = df.string(from: firstOfMonth)

        cachedMonthData = MonthData(
            year: year, month: month, title: title,
            weekRows: weekRows, perfectWeeks: perfectWeeks
        )
    }

    private func rebuildHeatmap() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weeks = effectiveWeeksToShow

        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }

        let todayWeekday = cal.component(.weekday, from: today)
        let daysBack = (weeks - 1) * 7 + (todayWeekday - 1)
        guard let startDate = cal.date(byAdding: .day, value: -daysBack, to: today) else { return }

        // Study minutes for entire range
        let studyMinutes = studyTimeTracker.minutesForDateRange(from: startDate, to: today)

        var builtWeeks: [[DayActivity]] = []
        var currentDate = startDate
        var allMax = 0

        for _ in 0..<weeks {
            var week: [DayActivity] = []
            for _ in 0..<daysInWeek {
                let wordsForDay = grouped[currentDate] ?? []
                let count = wordsForDay.count
                if count > allMax { allMax = count }
                let isFuture = currentDate > today
                let wordNames = Array(wordsForDay.prefix(5).map { $0.word })

                week.append(DayActivity(
                    date: currentDate,
                    count: count,
                    isFuture: isFuture,
                    isToday: currentDate == today,
                    studyMinutes: studyMinutes[currentDate] ?? 0,
                    words: wordNames,
                    isStreakMilestone: cachedMilestones.contains(currentDate)
                ))
                currentDate = cal.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            builtWeeks.append(week)
        }

        cachedCalendar = builtWeeks
        cachedMaxCount = max(allMax, 1)

        // Month labels
        let df = DateFormatter()
        df.dateFormat = "MMM"
        var labels: [(String, Int)] = []
        var lastMonth = -1
        for weekIndex in 0..<weeks {
            guard let weekStart = cal.date(byAdding: .day, value: weekIndex * 7, to: startDate) else { continue }
            let month = cal.component(.month, from: weekStart)
            if month != lastMonth {
                labels.append((df.string(from: weekStart), weekIndex))
                lastMonth = month
            }
        }
        cachedMonthLabels = labels
    }

    private func rebuildStats() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }

        var stats = CalendarStats()

        // Determine range start based on mode
        let rangeStart: Date
        if selectedMode == .month {
            if let md = cachedMonthData {
                rangeStart = cal.date(from: DateComponents(year: md.year, month: md.month, day: 1)) ?? today
            } else {
                rangeStart = today
            }
        } else {
            let weeks = effectiveWeeksToShow
            let todayWeekday = cal.component(.weekday, from: today)
            let daysBack = (weeks - 1) * 7 + (todayWeekday - 1)
            rangeStart = cal.date(byAdding: .day, value: -daysBack, to: today) ?? today
        }

        let rangeGrouped = grouped.filter { $0.key >= rangeStart && $0.key <= today }
        let activeDates = Set(rangeGrouped.keys.filter { (rangeGrouped[$0]?.count ?? 0) > 0 })
        stats.totalActiveDays = activeDates.count

        // Current streak (always from today)
        let allActiveDates = Set(grouped.keys.filter { (grouped[$0]?.count ?? 0) > 0 })
        var day = today
        var streak = 0
        while allActiveDates.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        stats.currentStreak = streak

        // Longest streak within range
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

        // Best day within range
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
        while allDates.contains(day) {
            dates.insert(day)
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
