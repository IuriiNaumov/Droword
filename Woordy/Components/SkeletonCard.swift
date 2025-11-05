import SwiftUI

struct Skeleton: View {
    var body: some View {
        VStack(spacing: 18) {
            SkeletonWordCardView(isExpanded: true)
            SkeletonWordCardView(isExpanded: true)
        }
        .padding(.horizontal, 8)
    }
}

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
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
        .padding(.top, 12)
        .redacted(reason: .placeholder)
    }
}

extension View {
    func shimmering(active: Bool = true, speed: Double = 1.25) -> some View {
        modifier(ShimmerModifier(active: active, speed: speed))
    }
}

private struct ShimmerModifier: ViewModifier {
    let active: Bool
    let speed: Double

    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if active {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.white.opacity(0.32),
                                .clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .rotationEffect(.degrees(18))
                        .offset(x: geo.size.width * phase)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .mask(content)
                        .onAppear {
                            withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                                phase = 2.2
                            }
                        }
                    }
                }
            )
    }
}

#Preview("Skeleton Shimmer Card") {
    Skeleton()
}
