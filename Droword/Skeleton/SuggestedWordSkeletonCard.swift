import SwiftUI

struct SuggestedWordSkeletonCard: View {
    @EnvironmentObject private var themeStore: ThemeStore

    private var accent: Color { themeStore.accentBlue }
    private var softAccent: Color { themeStore.accentBlue.opacity(0.25) }
    private var warmAccent: Color { themeStore.accentBlue.opacity(0.12) }

    @State private var shimmerPhase: CGFloat = -1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.7))
                .frame(width: 110, height: 26)
                .suggestedShimmer(phase: shimmerPhase)

            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.6))
                .frame(width: 90, height: 18)
                .suggestedShimmer(phase: shimmerPhase)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.5))
                .frame(width: 240, height: 16)
                .suggestedShimmer(phase: shimmerPhase)

            HStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 90, height: 28)
                    .suggestedShimmer(phase: shimmerPhase)

                Spacer()

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 92, height: 24)
                    .suggestedShimmer(phase: shimmerPhase)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [softAccent, accent.opacity(0.15), warmAccent]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerPhase = 2.0
            }
        }
    }
}

extension View {
    func suggestedShimmer(phase: CGFloat) -> some View {
        self.overlay(
            GeometryReader { geo in
                let gradient = LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.white.opacity(0.5),
                        Color.accentBlue.opacity(0.3),
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
