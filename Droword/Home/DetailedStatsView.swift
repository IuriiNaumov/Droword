import SwiftUI
import Charts

struct DetailedStatsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var studyTimeTracker: StudyTimeTracker
    @ObservedObject private var studyActivity = StudyActivityStore.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.currentStreak) private var currentStreak: Int = 0

    var embedded: Bool = false

    @State private var dueToday: Int = 0
    @State private var dueSoon: Int = 0
    @State private var masteryBreakdown: (new: Int, learning: Int, known: Int) = (0, 0, 0)
    @State private var studiedThisWeek: Int = 0
    @State private var weakWords: [(word: String, lapses: Int)] = []
    @State private var tagDistribution: [(tag: String, count: Int)] = []

    private static let pieColors: [Color] = [
        Color.accentBlue, Color.accentGreen, Color.accentGold,
        Color.accentPurple, Color.accentPink, Color.accentRed, .indigo, .mint
    ]

    var body: some View {
        if embedded {
            statsStack
                .onAppear(perform: recalculate)
                .onChange(of: store.revision) { _, _ in recalculate() }
                .onChange(of: studyActivity.dayKeys) { _, _ in recalculate() }
        } else {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    statsStack
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .iPadContentWidth()
                }
                .background(themeStore.appBg.ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton()
                    }
                }
                .onAppear(perform: recalculate)
                .onChange(of: store.revision) { _, _ in recalculate() }
            }
        }
    }

    private var statsStack: some View {
        VStack(spacing: 20) {
            if !embedded {
                Text("Your progress")
                    .sheetTitle()
            }

            snapshotSection
            masterySection
            focusSection
            habitSection
            studyTimeSection

            if !weakWords.isEmpty {
                weakWordsSection
            }

            if !tagDistribution.isEmpty {
                tagChartSection
            }
        }
    }

    private func recalculate() {
        let words = store.words
        let now = Date()
        let cal = Calendar.current
        let weekStart = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now

        dueToday = words.filter {
            WordDue.isDue(introduced: $0.introduced, dueDate: $0.dueDate, now: now)
        }.count

        let weekEnd = cal.date(byAdding: .day, value: 7, to: now) ?? now
        dueSoon = words.filter { w in
            guard w.introduced, let due = w.dueDate else { return false }
            return due > now && due <= weekEnd
        }.count

        var n = 0, l = 0, k = 0
        for w in words {
            if !w.introduced || w.repetitions == 0 {
                n += 1
            } else if w.intervalDays >= 21 || w.repetitions >= 5 {
                k += 1
            } else {
                l += 1
            }
        }
        masteryBreakdown = (n, l, k)

        studiedThisWeek = studyActivity.activityDates().filter { $0 >= weekStart }.count

        weakWords = words
            .filter { $0.lapses > 0 }
            .sorted { $0.lapses > $1.lapses }
            .prefix(5)
            .map { (word: $0.word.displayCapitalized, lapses: $0.lapses) }

        var tagDict: [String: Int] = [:]
        for w in words {
            tagDict[w.tag ?? String(localized: "No tag"), default: 0] += 1
        }
        tagDistribution = tagDict.sorted { $0.value > $1.value }.map { (tag: $0.key, count: $0.value) }
    }

    private var snapshotSection: some View {
        let known = masteryBreakdown.known
        let total = store.words.count
        let knownShare = total > 0 ? Int(round(Double(known) / Double(total) * 100)) : 0

        return sectionCard(title: "At a glance", subtitle: String(localized: "How your dictionary is growing")) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                snapshotTile(
                    value: "\(total)",
                    label: String(localized: "In dictionary"),
                    tint: themeStore.accentBlue
                )
                snapshotTile(
                    value: "\(known)",
                    label: String(localized: "Known · \(knownShare)%"),
                    tint: themeStore.accentGreen
                )
                snapshotTile(
                    value: "\(dueToday)",
                    label: String(localized: "Due today"),
                    tint: dueToday > 0 ? themeStore.accentGold : themeStore.secondaryText
                )
                snapshotTile(
                    value: "\(max(currentStreak, WordsStore.computeCurrentStreak(from: store.words)))",
                    label: String(localized: "Day streak"),
                    tint: themeStore.accentPink
                )
            }

            if let level = cefrLine {
                Text(level)
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }

    private var cefrLine: String? {
        let level = languageStore.learningLevel
        guard !level.isEmpty else { return nil }
        return String(localized: "Learning level: \(level)")
    }

    private func snapshotTile(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(themeStore.bold(28))
                .foregroundStyle(themeStore.mainText)
                .contentTransition(.numericText())
            Text(label)
                .font(themeStore.regular(12))
                .foregroundStyle(themeStore.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.small, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }

    private var masterySection: some View {
        let m = masteryBreakdown
        let total = max(store.words.count, 1)

        return sectionCard(
            title: "Mastery",
            subtitle: String(localized: "New → learning → known as you review")
        ) {
            VStack(spacing: 12) {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeStore.accentGold.opacity(0.85))
                            .frame(width: max(0, geo.size.width * CGFloat(m.new) / CGFloat(total)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeStore.accentBlue.opacity(0.85))
                            .frame(width: max(0, geo.size.width * CGFloat(m.learning) / CGFloat(total)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeStore.accentGreen.opacity(0.85))
                            .frame(width: max(0, geo.size.width * CGFloat(m.known) / CGFloat(total)))
                    }
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack(spacing: 12) {
                    masteryLabel(color: themeStore.accentGold, title: String(localized: "New"), count: m.new)
                    masteryLabel(color: themeStore.accentBlue, title: String(localized: "Learning"), count: m.learning)
                    masteryLabel(color: themeStore.accentGreen, title: String(localized: "Known"), count: m.known)
                }
            }
        }
    }

    private func masteryLabel(color: Color, title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(title) (\(count))")
                .font(themeStore.regular(13))
                .foregroundStyle(themeStore.mainText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var focusSection: some View {
        sectionCard(title: "Focus", subtitle: String(localized: "What moves you forward next")) {
            VStack(alignment: .leading, spacing: 12) {
                focusRow(
                    icon: "clock.arrow.circlepath",
                    title: dueToday == 0
                        ? String(localized: "Nothing due right now")
                        : String(localized: "\(dueToday) words ready to review"),
                    detail: dueSoon > 0
                        ? String(localized: "+\(dueSoon) more in the next 7 days")
                        : String(localized: "Keep the streak with a short lesson")
                )

                if let lesson = studyActivity.lastLesson, lesson.total > 0 {
                    let pct = Int(round(Double(lesson.correct) / Double(lesson.total) * 100))
                    focusRow(
                        icon: "checkmark.circle",
                        title: String(localized: "Last lesson · \(pct)%"),
                        detail: String(localized: "\(lesson.correct) of \(lesson.total) correct")
                    )
                }
            }
        }
    }

    private func focusRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .symbolVariant(.none)
                .foregroundStyle(themeStore.mainText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(themeStore.medium(15))
                    .foregroundStyle(themeStore.mainText)
                Text(detail)
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
            }

            Spacer(minLength: 0)
        }
    }

    private var habitSection: some View {
        sectionCard(title: "Habit", subtitle: String(localized: "Consistency beats cramming")) {
            HStack(spacing: 12) {
                studyTimeStat(value: "\(studiedThisWeek)/7", label: String(localized: "Days this week"))
                studyTimeStat(
                    value: "\(max(currentStreak, WordsStore.computeCurrentStreak(from: store.words)))",
                    label: String(localized: "Streak")
                )
                studyTimeStat(value: studyTimeTracker.todayFormatted, label: String(localized: "Today"))
            }
        }
    }

    private var studyTimeSection: some View {
        let data = studyTimeTracker.minutesPerDay(last: 14)
        let maxMin = data.map(\.minutes).max() ?? 1

        return sectionCard(
            title: "Time in app",
            subtitle: String(localized: "Minutes the app was open — a rough signal")
        ) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    studyTimeStat(value: studyTimeTracker.todayFormatted, label: String(localized: "Today"))
                    studyTimeStat(value: studyTimeTracker.weekFormatted, label: String(localized: "This week"))
                    studyTimeStat(
                        value: StudyTimeTracker.format(seconds: studyTimeTracker.averageDailyMinutes * 60),
                        label: String(localized: "Avg/day")
                    )
                }

                if data.contains(where: { $0.minutes > 0 }) {
                    Chart {
                        ForEach(data, id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Minutes", item.minutes)
                            )
                            .foregroundStyle(themeStore.accentBlue)
                            .cornerRadius(3)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .font(themeStore.regular(10))
                                .foregroundStyle(themeStore.secondaryText)
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(themeStore.dividerColor)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .font(themeStore.regular(10))
                                .foregroundStyle(themeStore.secondaryText)
                        }
                    }
                    .chartYScale(domain: 0...(max(maxMin, 1)))
                    .frame(height: 120)
                } else {
                    Text("Start learning to see your time chart")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func studyTimeStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)
            Text(label)
                .font(themeStore.regular(12))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var weakWordsSection: some View {
        sectionCard(
            title: "Needs more love",
            subtitle: String(localized: "Words you missed most — good to revisit")
        ) {
            VStack(spacing: 8) {
                ForEach(Array(weakWords.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.word)
                            .font(themeStore.medium(15))
                            .foregroundStyle(themeStore.mainText)
                        Spacer()
                        Text(String(localized: "\(item.lapses) misses"))
                            .font(themeStore.regular(13))
                            .foregroundStyle(themeStore.secondaryText)
                    }
                }
            }
        }
    }

    private var tagChartSection: some View {
        let tags = tagDistribution

        return sectionCard(title: "By tags", subtitle: nil) {
            HStack(spacing: 16) {
                Chart {
                    ForEach(Array(tags.prefix(8).enumerated()), id: \.offset) { index, item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Self.pieColors[index % Self.pieColors.count])
                        .cornerRadius(4)
                    }
                }
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(tags.prefix(5).enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Self.pieColors[index % Self.pieColors.count])
                                .frame(width: 8, height: 8)
                            Text(BuiltInTag.displayName(item.tag))
                                .font(themeStore.regular(13))
                                .foregroundStyle(themeStore.mainText)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.count)")
                                .font(themeStore.bold(13))
                                .foregroundStyle(themeStore.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        title: LocalizedStringKey,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(themeStore.bold(18))
                    .foregroundStyle(themeStore.mainText)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.card))
        .cardDepth(cornerRadius: DesignRadius.card)
    }
}

#Preview {
    DetailedStatsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
        .environmentObject(StudyTimeTracker.shared)
}
