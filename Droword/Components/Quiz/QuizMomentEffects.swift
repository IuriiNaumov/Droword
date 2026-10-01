import SwiftUI

struct OnFireBurstView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var played = false

    var body: some View {
        GeometryReader { geo in
            let origin = CGPoint(x: geo.size.width - 56, y: 22)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                StreakFireStyle.red.opacity(played ? 0 : 0.42),
                                Color(hex: "#FF9F0A").opacity(played ? 0 : 0.16),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: played ? 320 : 24
                        )
                    )
                    .frame(width: 640, height: 640)
                    .position(origin)

                if !reduceMotion {
                    ForEach(OnFireEmber.samples) { ember in
                        Circle()
                            .fill(ember.gold ? Color(hex: "#FF9F0A") : StreakFireStyle.red)
                            .frame(width: ember.size, height: ember.size)
                            .position(
                                x: origin.x + (played ? ember.dx : 0),
                                y: origin.y + (played ? ember.dy : 0)
                            )
                            .scaleEffect(played ? 0.25 : 1)
                            .opacity(played ? 0 : 1)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.2 : 0.68)) {
                played = true
            }
        }
    }
}

private struct OnFireEmber: Identifiable {
    let id: Int
    let dx: CGFloat
    let dy: CGFloat
    let size: CGFloat
    let gold: Bool

    static let samples: [OnFireEmber] = [
        OnFireEmber(id: 0, dx: -36, dy: 28, size: 11, gold: false),
        OnFireEmber(id: 1, dx: -92, dy: 64, size: 8, gold: true),
        OnFireEmber(id: 2, dx: -150, dy: 18, size: 7, gold: false),
        OnFireEmber(id: 3, dx: -24, dy: 118, size: 9, gold: true),
        OnFireEmber(id: 4, dx: -188, dy: 86, size: 6, gold: false),
        OnFireEmber(id: 5, dx: -110, dy: 148, size: 8, gold: true),
        OnFireEmber(id: 6, dx: -230, dy: 36, size: 5, gold: false),
        OnFireEmber(id: 7, dx: -64, dy: 186, size: 7, gold: false),
        OnFireEmber(id: 8, dx: -168, dy: 160, size: 6, gold: true),
        OnFireEmber(id: 9, dx: 8, dy: 78, size: 8, gold: true)
    ]
}

struct PracticeFinishBurstView: View {
    var accent: Color
    var message: String
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var revealed = 0
    @State private var litSparkles = 0
    @State private var sparkleFade = false
    @State private var didFinish = false

    private var characters: [Character] { Array(message) }

    private var readsRightToLeft: Bool {
        message.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0590...0x08FF, 0xFB1D...0xFEFF:
                return true
            default:
                return false
            }
        }
    }

    var body: some View {
        ZStack {
            accent.ignoresSafeArea()

            ZStack {
                finishSparkles
                    .opacity(sparkleFade ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: sparkleFade)
                letters
            }
        }
        .onAppear(perform: play)
    }

    private var letters: some View {
        HStack(spacing: 0) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                Text(character == " " ? "\u{00A0}" : String(character))
                    .font(themeStore.display(44))
                    .foregroundStyle(.white)
                    .scaleEffect(index < revealed ? 1 : 0.35)
                    .offset(y: index < revealed ? 0 : 20)
                    .opacity(index < revealed ? 1 : 0)
            }
        }
        .environment(\.layoutDirection, readsRightToLeft ? .rightToLeft : .leftToRight)
        .animation(.bouncy(duration: 0.52, extraBounce: 0.16), value: revealed)
        .padding(.horizontal, 28)
    }

    private var finishSparkles: some View {
        ZStack {
            ForEach(FinishSparkle.samples) { sparkle in
                Image(systemName: sparkle.symbol)
                    .font(.system(size: sparkle.size, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(sparkle.turn))
                    .scaleEffect(sparkle.id < litSparkles ? 1 : 0.15)
                    .opacity(sparkle.id < litSparkles ? 1 : 0)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .animation(.spring(response: 0.42, dampingFraction: 0.58), value: litSparkles)
            }
        }
        .allowsHitTesting(false)
    }

    private func play() {
        let count = characters.count
        Task { @MainActor in
            if reduceMotion {
                revealed = count
                litSparkles = FinishSparkle.samples.count
                try? await Task.sleep(for: .milliseconds(420))
                finish()
                return
            }

            let step = max(72, min(110, 980 / max(count, 1)))
            async let letters: Void = revealLetters(count: count, step: step)
            async let stars: Void = revealSparkles(letterStep: step, letterCount: count)
            _ = await (letters, stars)

            try? await Task.sleep(for: .milliseconds(360))
            sparkleFade = true
            try? await Task.sleep(for: .milliseconds(560))
            finish()
        }
    }

    private func revealLetters(count: Int, step: Int) async {
        for index in 0..<count {
            revealed = index + 1
            try? await Task.sleep(for: .milliseconds(step))
        }
    }

    private func revealSparkles(letterStep: Int, letterCount: Int) async {
        let total = FinishSparkle.samples.count
        let span = max(letterStep * max(letterCount, 1), 720)
        let step = max(120, span / max(total, 1))
        try? await Task.sleep(for: .milliseconds(90))
        for index in 0..<total {
            litSparkles = index + 1
            Haptics.sparkleTick()
            try? await Task.sleep(for: .milliseconds(step))
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

private struct FinishSparkle: Identifiable {
    let id: Int
    let symbol: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
    let turn: Double

    static let samples: [FinishSparkle] = [
        FinishSparkle(id: 0, symbol: "sparkle", x: -132, y: -46, size: 16, delay: 0.0, turn: -18),
        FinishSparkle(id: 1, symbol: "star.fill", x: -156, y: 22, size: 8, delay: 0.08, turn: 12),
        FinishSparkle(id: 2, symbol: "sparkle", x: 8, y: -54, size: 12, delay: 0.14, turn: 8),
        FinishSparkle(id: 3, symbol: "sparkle", x: 138, y: -38, size: 18, delay: 0.04, turn: 16),
        FinishSparkle(id: 4, symbol: "star.fill", x: 158, y: 18, size: 9, delay: 0.16, turn: -10),
        FinishSparkle(id: 5, symbol: "sparkle", x: -36, y: 50, size: 10, delay: 0.22, turn: 20),
        FinishSparkle(id: 6, symbol: "sparkle", x: 96, y: 48, size: 13, delay: 0.1, turn: -14)
    ]
}
