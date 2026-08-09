import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var studyTimeTracker: StudyTimeTracker
    @State private var showDetailedStats = false
    @State private var cachedTodayCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stats")
                    .font(themeStore.bold(24))
                    .foregroundStyle(themeStore.mainText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
            }

            HStack(spacing: 12) {
                StatCardView(title: "Total", value: "\(store.totalWordsAdded)")
                StatCardView(title: "Today", value: "\(cachedTodayCount)")
                StatCardView(title: "Time", value: studyTimeTracker.todayFormatted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 24))
        .cardDepth(cornerRadius: 24)
        .foregroundStyle(themeStore.mainText)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Stats: \(store.totalWordsAdded) total, \(cachedTodayCount) today"))
        .accessibilityHint(Text("Tap for detailed statistics"))
        .onTapGesture { showDetailedStats = true }
        .onAppear { recalcToday() }
        .onChange(of: store.revision) { recalcToday() }
        .fullScreenCover(isPresented: $showDetailedStats) {
            DetailedStatsView()
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    private func recalcToday() {
        let calendar = Calendar.current
        cachedTodayCount = store.words.filter { calendar.isDateInToday($0.dateAdded) }.count
    }
}

#Preview {
    StatsView().environmentObject(WordsStore())
}
