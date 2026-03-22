import SwiftUI

struct SkeletonWordCardView: View {
    var isExpanded: Bool = true
    var height: CGFloat = 0

    private var backgroundColor: Color { Color(.systemGray5) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 100, height: 28)
                    .shimmering()
                Spacer()
                Circle()
                    .fill(Color.gray.opacity(0.28))
                    .frame(width: 24, height: 24)
                    .shimmering()
            }
            
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.gray.opacity(0.22))
                .frame(width: 70, height: 18)
                .shimmering()
            
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 120, height: 20)
                .shimmering()
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: 210, height: 18)
                    .shimmering()
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: 135, height: 18)
                    .shimmering()
            }
            
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.gray.opacity(0.16))
                .frame(width: 110, height: 14)
                .padding(.top, 2)
                .shimmering()
            
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: 22, height: 22)
                    .shimmering()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(24)
        .padding(.top, 12)
        .redacted(reason: .placeholder)
    }
}
