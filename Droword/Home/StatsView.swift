import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
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
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.mainBlack)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mainGrey.opacity(0.6))
            }

            HStack(spacing: 12) {
                StatCardView(title: "Total", value: "\(totalWordsEver)")
                StatCardView(title: "Today", value: "\(wordsAddedToday)")
                StatCardView(title: "Last 7 days", value: "\(wordsAddedLastWeek)")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.divider, lineWidth: 1)
                )
        )
        .foregroundColor(.mainBlack)
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
