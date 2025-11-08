import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: WordsStore

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

    private var firstWordDate: Date? {
        store.words.map { $0.dateAdded }.min()
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your stats")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(Color(.mainBlack))

            HStack(spacing: 20) {
                StatCardView(title: "Total", value: "\(totalWordsEver)")
                StatCardView(title: "Today", value: "\(wordsAddedToday)")
                StatCardView(title: "Last 7 days", value: "\(wordsAddedLastWeek)")
            }

        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.settingsBackground)
        )
        .foregroundColor(.mainBlack)
        .padding(.horizontal)
    }
}

#Preview {
    StatsView().environmentObject(WordsStore())
}
