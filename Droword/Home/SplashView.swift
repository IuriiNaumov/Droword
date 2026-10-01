import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onFinished: () -> Void

    @State private var join: CGFloat = 1
    @State private var wOn = false
    @State private var sidesOn = false
    @State private var sparkleOn = false
    @State private var exit: CGFloat = 0

    private let travel: CGFloat = 72

    private let sparkles: [SplashSparkle] = [
        SplashSparkle(id: 0, symbol: "sparkle", x: -132, y: -46, size: 16, delay: 0.0, turn: -18),
        SplashSparkle(id: 1, symbol: "star.fill", x: -156, y: 22, size: 8, delay: 0.08, turn: 12),
        SplashSparkle(id: 2, symbol: "sparkle", x: 8, y: -54, size: 12, delay: 0.14, turn: 8),
        SplashSparkle(id: 3, symbol: "sparkle", x: 138, y: -38, size: 18, delay: 0.04, turn: 16),
        SplashSparkle(id: 4, symbol: "star.fill", x: 158, y: 18, size: 9, delay: 0.16, turn: -10),
        SplashSparkle(id: 5, symbol: "sparkle", x: -36, y: 50, size: 10, delay: 0.22, turn: 20),
        SplashSparkle(id: 6, symbol: "sparkle", x: 96, y: 48, size: 13, delay: 0.1, turn: -14)
    ]

    private var splashBg: Color {
        colorScheme == .dark ? .black : .white
    }

    private var splashText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var split: CGFloat { (1 - join) * travel }

    var body: some View {
        ZStack {
            splashBg.ignoresSafeArea()

            wordmark
                .opacity(1 - exit)
                .scaleEffect(1 - exit * 0.04)

            if !reduceMotion {
                sparkleField
                    .opacity(1 - exit)
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
        .task { await play() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Droword"))
    }

    private var wordmark: some View {
        HStack(spacing: -1.6) {
            sideLetter("d", x: -split)
            sideLetter("r", x: -split)
            sideLetter("o", x: -split)

            Text("w")
                .opacity(wOn ? 1 : 0)
                .scaleEffect(wOn ? 1 : 0.88)
                .zIndex(1)

            sideLetter("o", x: split)
            sideLetter("r", x: split)
            sideLetter("d", x: split)
        }
        .font(themeStore.display(48))
        .foregroundStyle(splashText)
    }

    private var sparkleField: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(sparkles) { sparkle in
                    let twinkle = 0.45 + 0.55 * abs(sin(time * 3.4 + sparkle.delay * 9))
                    Image(systemName: sparkle.symbol)
                        .font(.system(size: sparkle.size, weight: .semibold))
                        .foregroundStyle(splashText)
                        .rotationEffect(.degrees(sparkle.turn))
                        .scaleEffect(sparkleOn ? twinkle : 0.15)
                        .opacity(sparkleOn ? twinkle : 0)
                        .offset(
                            x: sparkle.x * (sparkleOn ? 1 : 0.65),
                            y: sparkle.y * (sparkleOn ? 1 : 0.65)
                        )
                        .animation(
                            .spring(response: 0.42, dampingFraction: 0.58).delay(sparkle.delay),
                            value: sparkleOn
                        )
                }
            }
        }
    }

    private func sideLetter(_ text: String, x: CGFloat) -> some View {
        Text(text)
            .offset(x: x)
            .opacity(sidesOn ? 1 : 0)
    }

    @MainActor
    private func play() async {
        if reduceMotion {
            wOn = true
            sidesOn = true
            join = 1
            try? await Task.sleep(for: .milliseconds(480))
            await finish()
            return
        }

        withAnimation(.easeOut(duration: 0.35)) {
            wOn = true
        }
        try? await Task.sleep(for: .milliseconds(280))

        withAnimation(.easeOut(duration: 0.45)) {
            sidesOn = true
            join = 0
        }
        try? await Task.sleep(for: .milliseconds(520))

        withAnimation(.spring(duration: 0.55, bounce: 0.12)) {
            join = 1
        }
        sparkleOn = true
        Haptics.sparkle()
        try? await Task.sleep(for: .milliseconds(700))

        await finish()
    }

    @MainActor
    private func finish() async {
        withAnimation(.easeIn(duration: 0.28)) {
            exit = 1
        }
        try? await Task.sleep(for: .milliseconds(300))
        onFinished()
    }
}

private struct SplashSparkle: Identifiable {
    let id: Int
    let symbol: String
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
