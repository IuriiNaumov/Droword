import SwiftUI

struct DetailedStatsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var statColor: Color {
        colorScheme == .dark ? Color(hex: "#6F68A8") : Color(hex: "#CBCDEA")
    }

    private var statTextColor: Color {
        darkerShade(of: statColor, by: colorScheme == .dark ? 0.3 : 0.4)
    }

    // MARK: - Computed Stats

    private var wordsAddedToday: Int {
        let cal = Calendar.current
        return store.words.filter { cal.isDateInToday($0.dateAdded) }.count
    }

    private var wordsAddedLastWeek: Int {
        let cal = Calendar.current
        guard let ago = cal.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return store.words.filter { $0.dateAdded >= ago }.count
    }

    private var currentStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dates = Set(store.words.map { cal.startOfDay(for: $0.dateAdded) })

        var streak = 0
        var day = today
        while dates.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

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

    private var last14Days: [(date: Date, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let grouped = Dictionary(grouping: store.words) { cal.startOfDay(for: $0.dateAdded) }

        return (0..<14).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (day, grouped[day]?.count ?? 0)
        }
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

    private var shortDayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EE"
        return f
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    overviewSection
                    activitySection
                    masterySection
                    reviewSection
                    tagSection
                    typeSection
                    factsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        HStack(spacing: 12) {
            miniStatCard(value: "\(store.totalWordsAdded)", label: "Total")
            miniStatCard(value: "\(wordsAddedToday)", label: "Today")
            miniStatCard(value: "\(wordsAddedLastWeek)", label: "7 days")
            miniStatCard(value: "\(currentStreak)", label: "Streak")
        }
    }

    private func miniStatCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(statTextColor)
            Text(label)
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundColor(statTextColor.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(statColor.opacity(colorScheme == .dark ? 0.9 : 1.0))
        )
    }

    // MARK: - Activity Chart

    private var activitySection: some View {
        let data = last14Days
        let maxCount = max(data.map(\.count).max() ?? 1, 1)

        return sectionCard(title: "Activity", icon: "chart.bar.fill") {
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.count > 0 ? Color.toastAndButtons : Color.mainGrey.opacity(0.2))
                                .frame(height: max(4, CGFloat(item.count) / CGFloat(maxCount) * 80))

                            Text(shortDayFormatter.string(from: item.date).prefix(1))
                                .font(.system(size: 9))
                                .foregroundColor(.mainGrey)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)

                Text("Last 14 days")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.mainGrey)
            }
        }
    }

    // MARK: - Mastery

    private var masterySection: some View {
        let m = masteryBreakdown
        let total = max(store.words.count, 1)

        return sectionCard(title: "Mastery", icon: "brain.fill") {
            VStack(spacing: 12) {
                // Progress bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: max(0, geo.size.width * CGFloat(m.new) / CGFloat(total)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.opacity(0.8))
                            .frame(width: max(0, geo.size.width * CGFloat(m.learning) / CGFloat(total)))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.7))
                            .frame(width: max(0, geo.size.width * CGFloat(m.known) / CGFloat(total)))
                    }
                }
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))

                HStack(spacing: 16) {
                    masteryLabel(color: Color.orange.opacity(0.7), title: "New", count: m.new)
                    masteryLabel(color: Color.yellow.opacity(0.8), title: "Learning", count: m.learning)
                    masteryLabel(color: Color.green.opacity(0.7), title: "Known", count: m.known)
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

    // MARK: - Review

    private var reviewSection: some View {
        sectionCard(title: "Review", icon: "arrow.clockwise") {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(dueToday)")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.primary)
                    Text("Due today")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.mainGrey)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("\(totalLapses)")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.primary)
                    Text("Total lapses")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.mainGrey)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f", averageEase))
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.primary)
                    Text("Avg ease")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.mainGrey)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Tags

    private var tagSection: some View {
        let tags = tagDistribution

        return Group {
            if !tags.isEmpty {
                sectionCard(title: "By tags", icon: "tag.fill") {
                    VStack(spacing: 8) {
                        ForEach(Array(tags.prefix(6).enumerated()), id: \.offset) { _, item in
                            HStack {
                                Text(item.tag)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.custom("Poppins-Bold", size: 14))
                                    .foregroundColor(.mainGrey)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Types

    private var typeSection: some View {
        let types = typeDistribution

        return Group {
            if !types.isEmpty {
                sectionCard(title: "Parts of speech", icon: "textformat.abc") {
                    VStack(spacing: 8) {
                        ForEach(Array(types.prefix(6).enumerated()), id: \.offset) { _, item in
                            HStack {
                                Text(item.type)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.custom("Poppins-Bold", size: 14))
                                    .foregroundColor(.mainGrey)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Fun Facts

    private var factsSection: some View {
        sectionCard(title: "Fun facts", icon: "sparkles") {
            VStack(alignment: .leading, spacing: 10) {
                if let best = bestDay {
                    factRow(
                        icon: "flame.fill",
                        text: "Best day: \(dateFormatter.string(from: best.date)) (\(best.count) words)"
                    )
                }

                factRow(
                    icon: "graduationcap.fill",
                    text: "Level: \(languageStore.learningLevel)"
                )

                if let first = store.words.map({ $0.dateAdded }).min() {
                    let days = max(1, Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 1)
                    factRow(
                        icon: "calendar",
                        text: "Learning for \(days) day\(days == 1 ? "" : "s")"
                    )
                }

                let avgPerDay: Double = {
                    guard let first = store.words.map({ $0.dateAdded }).min() else { return 0 }
                    let days = max(1, Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 1)
                    return Double(store.words.count) / Double(days)
                }()
                if avgPerDay > 0 {
                    factRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Average: \(String(format: "%.1f", avgPerDay)) words/day"
                    )
                }
            }
        }
    }

    private func factRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.toastAndButtons)
                .frame(width: 20)
            Text(text)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.toastAndButtons)
                Text(title)
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.primary)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    DetailedStatsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
}
