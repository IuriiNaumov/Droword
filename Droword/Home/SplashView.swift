import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onFinished: () -> Void

    @State private var shown = false
    @State private var exit = false

    private let logoSize: CGFloat = 48

    private let sparkles: [SplashSparkle] = [
        SplashSparkle(id: 0, tone: .purple, x: -132, y: -46, size: 30, delay: 0.0, turn: -12),
        SplashSparkle(id: 1, tone: .pink, x: -158, y: 22, size: 16, delay: 0.08, turn: 10),
        SplashSparkle(id: 2, tone: .gold, x: 8, y: -56, size: 22, delay: 0.14, turn: 6),
        SplashSparkle(id: 3, tone: .gold, x: 140, y: -40, size: 32, delay: 0.04, turn: 12),
        SplashSparkle(id: 4, tone: .blue, x: 160, y: 18, size: 16, delay: 0.16, turn: -8),
        SplashSparkle(id: 5, tone: .pink, x: -36, y: 52, size: 18, delay: 0.22, turn: 14),
        SplashSparkle(id: 6, tone: .purple, x: 98, y: 50, size: 24, delay: 0.1, turn: -10)
    ]

    private var splashBg: Color {
        colorScheme == .dark ? .black : .white
    }

    private var splashText: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        ZStack {
            splashBg.ignoresSafeArea()

            if !reduceMotion {
                sparkleField
                    .opacity(exit ? 0 : 1)
                    .allowsHitTesting(false)
            }

            DrowordWordmark(size: logoSize)
                .foregroundStyle(splashText)
                .blur(radius: shown || reduceMotion ? 0 : 12)
                .scaleEffect(shown || reduceMotion ? 1 : 0.92)
                .opacity(shown ? 1 : 0)
                .scaleEffect(exit ? 1.03 : 1)
                .opacity(exit ? 0 : 1)
        }
        .allowsHitTesting(false)
        .task { await play() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Droword"))
    }

    private var sparkleField: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(sparkles) { sparkle in
                    let twinkle = 0.45 + 0.55 * abs(sin(time * 3.4 + sparkle.delay * 9))
                    StickerStar(tone: sparkle.tone, size: sparkle.size)
                        .rotationEffect(.degrees(sparkle.turn))
                        .scaleEffect(shown ? twinkle : 0.15)
                        .opacity(shown ? twinkle : 0)
                        .offset(
                            x: sparkle.x * (shown ? 1 : 0.65),
                            y: sparkle.y * (shown ? 1 : 0.65)
                        )
                        .animation(
                            .spring(response: 0.42, dampingFraction: 0.58).delay(0.25 + sparkle.delay),
                            value: shown
                        )
                }
            }
        }
    }

    @MainActor
    private func play() async {
        try? await Task.sleep(for: .milliseconds(60))
        withAnimation(reduceMotion ? .easeOut(duration: 0.3) : .smooth(duration: 0.75)) {
            shown = true
        }
        if !reduceMotion {
            try? await Task.sleep(for: .milliseconds(300))
            Haptics.sparkle()
        }
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 700 : 900))
        withAnimation(.easeIn(duration: 0.28)) {
            exit = true
        }
        try? await Task.sleep(for: .milliseconds(300))
        onFinished()
    }
}

private struct SplashSparkle: Identifiable {
    let id: Int
    let tone: StickerTone
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
    let turn: Double
}

#Preview("Light") {
    SplashView(onFinished: {})
        .environmentObject(ThemeStore())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashView(onFinished: {})
        .environmentObject(ThemeStore())
        .preferredColorScheme(.dark)
}
