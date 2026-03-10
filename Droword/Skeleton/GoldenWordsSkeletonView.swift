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

struct GoldenWordSkeletonCard: View {
    private let baseGold = Color.accentGold
    private var softGold: Color { Color.accentGold.opacity(0.6) }
    private var warmBeige: Color { Color.accentGold.opacity(0.4) }
    private var shadowGold: Color { darkerShade(of: Color.accentGold, by: 0.15) }

    @State private var shimmerPhase: CGFloat = -1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.7))
                .frame(width: 110, height: 26)
                .goldShimmer(phase: shimmerPhase)

            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.6))
                .frame(width: 90, height: 18)
                .goldShimmer(phase: shimmerPhase)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.5))
                .frame(width: 240, height: 16)
                .goldShimmer(phase: shimmerPhase)

            HStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 90, height: 28)
                    .goldShimmer(phase: shimmerPhase)

                Spacer()

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 92, height: 24)
                    .goldShimmer(phase: shimmerPhase)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [softGold, baseGold, warmBeige]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.divider, lineWidth: 1)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerPhase = 2.0
            }
        }
    }
}

extension View {
    func goldShimmer(phase: CGFloat) -> some View {
        self.overlay(
            GeometryReader { geo in
                let gradient = LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.white.opacity(0.5),
                        Color.accentGold.opacity(0.3),
                        Color.white.opacity(0.5),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                Rectangle()
                    .fill(gradient)
                    .blendMode(.plusLighter)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(x: geo.size.width * (phase - 1))
                    .mask(self)
            }
        )
        .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: phase)
    }
}

#Preview("Soft Golden Skeleton") {
    GoldenWordsSkeletonView()
        .background(Color(.systemGroupedBackground))
}
