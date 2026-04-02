import SwiftUI
import Charts

struct DetailedStatsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var studyTimeTracker: StudyTimeTracker
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var dueToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return store.words.filter { w in
            if let due = w.dueDate { return due <= today }
            return true
        }.count
    }

    private var masteryBreakdown: (new: Int, learning: Int, known: Int) {
        var n = 0, l = 0, k = 0
        for w in store.words {
            switch w.repetitions {
            case 0: n += 1
            case 1...2: l += 1
            default: k += 1
            }
        }
        return (n, l, k)
    }

    private var totalLapses: Int {
        store.words.reduce(0) { $0 + $1.lapses }
    }

    private var averageEase: Double {
        guard !store.words.isEmpty else { return 0 }
        let sum = store.words.reduce(0.0) { $0 + $1.easeFactor }
        return sum / Double(store.words.count)
    }

    private var bestDay: (date: Date, count: Int)? {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }
        guard let best = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        return (best.key, best.value.count)
    }

    private var tagDistribution: [(tag: String, count: Int)] {
        var dict: [String: Int] = [:]
        for w in store.words {
            let tag = w.tag ?? "No tag"
            dict[tag, default: 0] += 1
        }
        return dict.sorted { $0.value > $1.value }.map { (tag: $0.key, count: $0.value) }
    }

    private var typeDistribution: [(type: String, count: Int)] {
        var dict: [String: Int] = [:]
        for w in store.words {
            let t = w.type.isEmpty ? "Other" : w.type.capitalized
            dict[t, default: 0] += 1
        }
        return dict.sorted { $0.value > $1.value }.map { (type: $0.key, count: $0.value) }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private static let pieColors: [Color] = [
        Color.accentBlue, Color.accentGreen, Color.accentGold, Color.accentPurple, Color.accentPink, Color.accentBlue, Color.accentGold, Color.accentRed, .indigo, .mint
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text("Stats")
                        .sheetTitle()

                    studyTimeSection
                    masterySection
                    reviewSection
                    tagChartSection
                    typeSection
                    factsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .iPadContentWidth()
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        CloseButtonIcon()
                            .environmentObject(themeStore)
                    }
                }
            }
        }
    }

    private var studyTimeSection: some View {
        let data = studyTimeTracker.minutesPerDay(last: 14)
        let maxMin = data.map { $0.minutes }.max() ?? 1

        return sectionCard(title: "Study time") {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    studyTimeStat(value: studyTimeTracker.todayFormatted, label: "Today")
                    studyTimeStat(value: studyTimeTracker.weekFormatted, label: "This week")
                    studyTimeStat(value: "\(studyTimeTracker.averageDailyMinutes)m", label: "Avg/day")
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
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundStyle(themeStore.secondaryText)
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(themeStore.dividerColor)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundStyle(themeStore.secondaryText)
                        }
                    }
                    .chartYScale(domain: 0...(max(maxMin, 1)))
                    .frame(height: 120)
                } else {
                    Text("Start learning to see your time chart")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.secondaryText)
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func studyTimeStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.primary)
            Text(label)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var masterySection: some View {
        let m = masteryBreakdown
        let total = max(store.words.count, 1)

        return sectionCard(title: "Mastery") {
            VStack(spacing: 12) {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: max(0, geo.size.width * CGFloat(m.new) / CGFloat(total)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.opacity(0.8))
                            .frame(width: max(0, geo.size.width * CGFloat(m.learning) / CGFloat(total)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentGreen.opacity(0.7))
                            .frame(width: max(0, geo.size.width * CGFloat(m.known) / CGFloat(total)))
                    }
                }
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))

                HStack(spacing: 16) {
                    masteryLabel(color: Color.accentRed.opacity(0.7), title: "New", count: m.new)
                    masteryLabel(color: Color.accentGold.opacity(0.8), title: "Learning", count: m.learning)
                    masteryLabel(color: Color.accentGreen.opacity(0.7), title: "Known", count: m.known)
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
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.primary)
        }
    }

    private var reviewSection: some View {
        sectionCard(title: "Review") {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(dueToday)")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.primary)
                    Text("Due today")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.secondaryText)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("\(totalLapses)")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.primary)
                    Text("Total lapses")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.secondaryText)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f", averageEase))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.primary)
                    Text("Avg ease")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var tagChartSection: some View {
        let tags = tagDistribution

        return Group {
            if !tags.isEmpty {
                sectionCard(title: "By tags") {
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
                        .frame(width: 120, height: 120)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(tags.prefix(6).enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Self.pieColors[index % Self.pieColors.count])
                                        .frame(width: 8, height: 8)
                                    Text(item.tag)
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(item.count)")
                                        .font(.custom("Poppins-Bold", size: 13))
                                        .foregroundColor(themeStore.secondaryText)
                                }
                            }
                            if tags.count > 6 {
                                Text("+\(tags.count - 6) more")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(themeStore.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    private var typeSection: some View {
        let types = typeDistribution

        return Group {
            if !types.isEmpty {
                sectionCard(title: "Parts of speech") {
                    VStack(spacing: 8) {
                        ForEach(Array(types.prefix(6).enumerated()), id: \.offset) { _, item in
                            HStack {
                                Text(item.type)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.custom("Poppins-Bold", size: 14))
                                    .foregroundColor(themeStore.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    private var factsSection: some View {
        sectionCard(title: "Fun facts") {
            VStack(alignment: .leading, spacing: 10) {
                if let best = bestDay {
                    factRow(text: "Best day: \(dateFormatter.string(from: best.date)) (\(best.count) words)")
                }

                if let first = store.words.map({ $0.dateAdded }).min() {
                    let days = max(1, Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 1)
                    factRow(text: "Learning for \(days) day\(days == 1 ? "" : "s")")
                }

                let totalMinutes = studyTimeTracker.totalAllTimeMinutes
                if totalMinutes > 0 {
                    factRow(text: "Total study time: \(StudyTimeTracker.format(seconds: totalMinutes * 60))")
                }
            }
        }
    }

    private func factRow(text: String) -> some View {
        Text(text)
            .font(.custom("Poppins-Regular", size: 14))
            .foregroundColor(.primary)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.primary)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }
}

#Preview {
    DetailedStatsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
}
