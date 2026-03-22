import SwiftUI

struct Skeleton: View {
    var body: some View {
        VStack(spacing: 18) {
            SkeletonWordCardView(isExpanded: true)
            SkeletonWordCardView(isExpanded: true)
        }
    }
}

#Preview("Skeleton Shimmer Card") {
    Skeleton()
}
