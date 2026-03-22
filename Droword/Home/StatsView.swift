import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var studyTimeTracker: StudyTimeTracker
    @State private var showDetailedStats = false

    private var totalWordsEver: Int {
        store.totalWordsAdded
    }

    private var wordsAddedToday: Int {
        let calendar = Calendar.current
        return store.words.filter { calendar.isDateInToday($0.dateAdded) }.count
    }

    private var wordsAddedLastWeek: Int {
        let calendar = Calendar.current
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return store.words.filter { $0.dateAdded >= oneWeekAgo }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stats")
                    .font(themeStore.bold(24))
                    .foregroundColor(themeStore.mainText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeStore.secondaryText.opacity(0.6))
            }

            HStack(spacing: 12) {
                StatCardView(title: "Total", value: "\(totalWordsEver)")
                StatCardView(title: "Today", value: "\(wordsAddedToday)")
                StatCardView(title: "Time", value: studyTimeTracker.todayFormatted)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeStore.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
                )
        )
        .foregroundColor(themeStore.mainText)
        .padding(.horizontal, 20)
        .onTapGesture { showDetailedStats = true }
        .fullScreenCover(isPresented: $showDetailedStats) {
            DetailedStatsView()
                .environmentObject(themeStore)
        }
    }
}

#Preview {
    StatsView().environmentObject(WordsStore())
}
