import SwiftUI

struct SuggestedWordsSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<2) { _ in
                SuggestedWordSkeletonCard()
            }
        }
        .padding(.bottom, 8)
    }
}

#Preview("Suggested Skeleton") {
    SuggestedWordsSkeletonView()
        .background(Color(.systemGroupedBackground))
}
