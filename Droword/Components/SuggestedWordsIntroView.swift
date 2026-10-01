import SwiftUI

struct SuggestedWordsIntroView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.4
    @State private var litSparkles = 0
    @State private var sparklesGone = false
    @State private var textOpacity: Double = 0
    @State private var bulletOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color { themeStore.accentPurple }

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                wandHero

                VStack(spacing: 8) {
                    Text("Suggested Words")
                        .font(themeStore.display(32))
                        .foregroundStyle(themeStore.mainText)
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)

                    Text("Smart suggestions just for you")
                        .font(themeStore.regular(16))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 18)
                .opacity(textOpacity)

                VStack(alignment: .leading, spacing: 16) {
                    bulletRow(
                        icon: "brain.head.profile",
                        text: "Based on words you already know"
                    )
                    bulletRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Helps expand your vocabulary naturally"
                    )
                    bulletRow(
                        icon: "plus.circle",
                        text: "Add them to your dictionary with one tap"
                    )
                }
                .padding(.top, 32)
                .opacity(bulletOpacity)

                Spacer(minLength: 24)

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Got it!")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: play)
    }

    private var wandHero: some View {
        ZStack {
            ForEach(WandSparkle.samples) { sparkle in
                Image(systemName: sparkle.symbol)
                    .font(.system(size: sparkle.size, weight: .semibold))
                    .foregroundStyle(sparkle.gold ? themeStore.accentGold : themeStore.mainAccentColor)
                    .rotationEffect(.degrees(sparkle.turn))
                    .scaleEffect(sparkle.id < litSparkles ? 1 : 0.15)
                    .opacity(sparkle.id < litSparkles ? 1 : 0)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .animation(.spring(response: 0.4, dampingFraction: 0.58), value: litSparkles)
            }
            .opacity(sparklesGone ? 0 : 1)
            .animation(.easeOut(duration: 0.45), value: sparklesGone)

            Image(systemName: "wand.and.sparkles")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(accent)
                .rotationEffect(.degrees(iconScale > 0.9 ? -8 : -22))
                .scaleEffect(iconScale)
                .opacity(iconScale > 0.5 ? 1 : 0)
        }
        .frame(height: 128)
        .accessibilityHidden(true)
    }

    private func play() {
        if reduceMotion {
            iconScale = 1
            textOpacity = 1
            bulletOpacity = 1
            buttonOpacity = 1
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            iconScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.22)) {
            bulletOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.32)) {
            buttonOpacity = 1
        }

        let total = WandSparkle.samples.count
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            for index in 0..<total {
                litSparkles = index + 1
                Haptics.sparkleTick()
                try? await Task.sleep(for: .milliseconds(120))
            }
            try? await Task.sleep(for: .milliseconds(280))
            sparklesGone = true
        }
    }

    private func bulletRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(darkerShade(of: accent, by: 0.3))
                .frame(width: 28)

            Text(text)
                .font(themeStore.regular(14))
                .foregroundStyle(themeStore.mainText.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Suggested words intro") {
    SuggestedWordsIntroView(onDismiss: {})
        .environmentObject(ThemeStore())
}

private struct WandSparkle: Identifiable {
    let id: Int
    let symbol: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let turn: Double
    let gold: Bool

    static let samples: [WandSparkle] = [
        WandSparkle(id: 0, symbol: "sparkle", x: 52, y: -42, size: 16, turn: 14, gold: true),
        WandSparkle(id: 1, symbol: "sparkles", x: 68, y: -6, size: 13, turn: -10, gold: false),
        WandSparkle(id: 2, symbol: "sparkle", x: 24, y: -54, size: 11, turn: 22, gold: false),
        WandSparkle(id: 3, symbol: "sparkle", x: -46, y: 18, size: 12, turn: -16, gold: true),
        WandSparkle(id: 4, symbol: "sparkles", x: 14, y: 34, size: 14, turn: 8, gold: false),
        WandSparkle(id: 5, symbol: "sparkle", x: -22, y: -36, size: 9, turn: -6, gold: false)
    ]
}
