import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: WordsStore
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
                    .foregroundColor(Color(.mainBlack))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mainGrey.opacity(0.6))
            }

            HStack(spacing: 20) {
                StatCardView(title: "Total", value: "\(totalWordsEver)")
                StatCardView(title: "Today", value: "\(wordsAddedToday)")
                StatCardView(title: "Last 7 days", value: "\(wordsAddedLastWeek)")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.cardBackground)
        )
        .foregroundColor(.mainBlack)
        .padding(.horizontal)
        .onTapGesture { showDetailedStats = true }
        .fullScreenCover(isPresented: $showDetailedStats) {
            DetailedStatsView()
        }
    }
}

#Preview {
    StatsView().environmentObject(WordsStore())
}
