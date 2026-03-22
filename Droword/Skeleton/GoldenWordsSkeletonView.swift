import SwiftUI

struct GoldenWordsSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<2) { _ in
                GoldenWordSkeletonCard()
            }
        }
        .padding(.bottom, 8)
    }
}

#Preview("Soft Golden Skeleton") {
    GoldenWordsSkeletonView()
        .background(Color(.systemGroupedBackground))
}
