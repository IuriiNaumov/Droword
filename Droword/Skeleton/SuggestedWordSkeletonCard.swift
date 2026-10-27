import SwiftUI

struct SuggestedWordSkeletonCard: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var shimmerPhase: CGFloat = -1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(themeStore.mainText.opacity(0.12))
                    .frame(width: 110, height: 26)
                    .suggestedShimmer(phase: shimmerPhase)
                Spacer()
                Circle()
                    .fill(themeStore.mainText.opacity(0.12))
                    .frame(width: 24, height: 24)
                    .suggestedShimmer(phase: shimmerPhase)
            }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(themeStore.mainText.opacity(0.1))
                .frame(width: 70, height: 16)
                .suggestedShimmer(phase: shimmerPhase)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(themeStore.mainText.opacity(0.1))
                .frame(width: 140, height: 18)
                .suggestedShimmer(phase: shimmerPhase)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(themeStore.mainText.opacity(0.08))
                .frame(width: 220, height: 16)
                .suggestedShimmer(phase: shimmerPhase)

            HStack {
                Capsule()
                    .fill(themeStore.mainText.opacity(0.1))
                    .frame(width: 72, height: 28)
                    .suggestedShimmer(phase: shimmerPhase)
                Spacer()
                Capsule()
                    .fill(themeStore.mainText.opacity(0.08))
                    .frame(width: 64, height: 28)
                    .suggestedShimmer(phase: shimmerPhase)
            }
            .padding(.top, 8)
        }
        .padding(DesignSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))
        .pixelFrame(themeStore)
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
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
                        themeAccentShimmer,
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
        .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: phase)
    }
}

private var themeAccentShimmer: Color {
    Color.accentBlue.opacity(0.3)
}

#Preview {
    SuggestedWordSkeletonCard()
        .padding()
        .environmentObject(ThemeStore())
}
