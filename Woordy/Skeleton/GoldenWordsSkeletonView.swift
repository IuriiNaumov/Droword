import SwiftUI

struct GoldenWordsSkeletonView: View {
    private let gold = Color(hex: "#FFC107")
    private let lightGold = Color(hex: "#FFE082")
    private let darkGold = Color(hex: "#E0A600")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 16) {
                ForEach(0..<2) { _ in
                    GoldenWordSkeletonCard()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 8)
    }
}

struct GoldenWordSkeletonCard: View {
    private let gold = Color(hex: "#FFC107")
    private let lightGold = Color(hex: "#FFE082")
    private let darkGold = Color(hex: "#E0A600")

    @State private var shimmerPhase: CGFloat = -1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.7))
                .frame(width: 110, height: 26)
                .goldShimmer(phase: shimmerPhase)

            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.65))
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
            RoundedRectangle(cornerRadius: 16)
                .fill(gold.gradientBackground())
        )
        .shadow(color: darkGold.opacity(0.18), radius: 10, y: 3)
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
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
                        Color.clear,
                        Color.white.opacity(0.55),
                        Color(hex: "#FFF8E1").opacity(0.92),
                        Color.white.opacity(0.55),
                        Color.clear
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
        .animation(.linear(duration: 1.3).repeatForever(autoreverses: false), value: phase)
    }
}

extension Color {
    func gradientBackground() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#FFE082"),
                Color(hex: "#FFC107"),
                Color(hex: "#FFD54F"),
                Color(hex: "#E0A600")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Golden Skeleton") {
    GoldenWordsSkeletonView()
        .background(Color(.systemGroupedBackground))
}
