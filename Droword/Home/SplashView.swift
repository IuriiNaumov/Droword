import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onFinished: () -> Void

    private let letters = ["D", "r", "o", "w", "o", "r", "d"]

    @State private var revealedCount = 0
    @State private var blobsOn = false
    @State private var sparksOn = false
    @State private var settled = false
    @State private var squeeze = false
    @State private var fly = false

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            if !reduceMotion {
                SplashMeshBackground(on: blobsOn, fly: fly)
            }

            ZStack {
                if !reduceMotion {
                    SplashSparks(on: sparksOn, fly: fly)
                }

                wordmark
            }
            .scaleEffect(wordScale)
            .opacity(fly ? 0 : 1)
            .blur(radius: fly ? 14 : 0)
        }
        .opacity(fly ? 0 : 1)
        .allowsHitTesting(false)
        .task { await play() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Droword"))
    }

    private var wordScale: CGFloat {
        if fly { return 1.55 }
        if squeeze { return 0.9 }
        if settled { return 1.03 }
        return 1
    }

    private var wordmark: some View {
        HStack(spacing: -1.6) {
            ForEach(letters.indices, id: \.self) { index in
                let shown = reduceMotion || revealedCount > index
                Text(letters[index])
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown ? 0 : 22)
                    .scaleEffect(shown ? 1 : 0.42)
                    .blur(radius: shown ? 0 : 7)
            }
        }
        .font(themeStore.display(48))
        .foregroundStyle(themeStore.mainText)
    }

    @MainActor
    private func play() async {
        if reduceMotion {
            revealedCount = letters.count
            blobsOn = true
            sparksOn = true
            settled = true
            Haptics.softTap()
            try? await Task.sleep(for: .milliseconds(520))
            await finish()
            return
        }

        Haptics.splash()

        withAnimation(.easeOut(duration: 0.7)) {
            blobsOn = true
        }

        try? await Task.sleep(for: .milliseconds(90))
        for index in letters.indices {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
                revealedCount = index + 1
            }
            try? await Task.sleep(for: .milliseconds(64))
        }

        try? await Task.sleep(for: .milliseconds(70))
        withAnimation(.spring(response: 0.62, dampingFraction: 0.78)) {
            settled = true
            sparksOn = true
        }

        try? await Task.sleep(for: .milliseconds(980))
        await finish()
    }

    @MainActor
    private func finish() async {
        Haptics.splashExit()
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.32)) {
                fly = true
            }
            try? await Task.sleep(for: .milliseconds(340))
            onFinished()
            return
        }

        withAnimation(.easeIn(duration: 0.12)) {
            squeeze = true
        }
        try? await Task.sleep(for: .milliseconds(110))
        withAnimation(.easeIn(duration: 0.46)) {
            fly = true
        }
        try? await Task.sleep(for: .milliseconds(470))
        onFinished()
    }
}

private struct SplashMeshBackground: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var on: Bool
    var fly: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                meshBlob(
                    color: themeStore.mainAccentColor,
                    size: 360,
                    x: cos(t * 0.38) * 30 - 36,
                    y: sin(t * 0.26) * 22 - 18
                )
                meshBlob(
                    color: themeStore.accentPink,
                    size: 300,
                    x: sin(t * 0.3) * 34 + 48,
                    y: cos(t * 0.22) * 20 + 28
                )
                meshBlob(
                    color: themeStore.accentGold,
                    size: 250,
                    x: cos(t * 0.22) * 18 + 8,
                    y: sin(t * 0.32) * 26 - 54
                )
            }
            .opacity(on ? (fly ? 0 : 1) : 0)
            .scaleEffect(on ? (fly ? 1.55 : 1) : 0.45)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func meshBlob(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.34))
            .frame(width: size, height: size)
            .blur(radius: 56)
            .offset(x: x, y: y)
    }
}

private struct SplashSparks: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var on: Bool
    var fly: Bool

    private let sparks: [SplashSpark] = [
        .init(id: 0, x: -122, y: -36, size: 15, speed: 2.4, phase: 0.2),
        .init(id: 1, x: -56, y: -58, size: 10, speed: 3.1, phase: 1.1),
        .init(id: 2, x: 22, y: -50, size: 13, speed: 2.7, phase: 0.6),
        .init(id: 3, x: 114, y: -26, size: 16, speed: 2.2, phase: 1.8),
        .init(id: 4, x: 132, y: 24, size: 9, speed: 3.4, phase: 0.4),
        .init(id: 5, x: 64, y: 50, size: 12, speed: 2.8, phase: 1.4),
        .init(id: 6, x: -92, y: 38, size: 11, speed: 3.0, phase: 0.9),
        .init(id: 7, x: -6, y: 54, size: 8, speed: 3.6, phase: 2.1),
        .init(id: 8, x: -148, y: 8, size: 7, speed: 2.9, phase: 0.5),
        .init(id: 9, x: 148, y: -8, size: 8, speed: 2.5, phase: 1.6)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let burst: CGFloat = fly ? 2.35 : 1
            ForEach(sparks) { spark in
                let wave = (sin(now * spark.speed + spark.phase) + 1) / 2
                Image(systemName: "sparkle")
                    .font(.system(size: spark.size, weight: .bold))
                    .foregroundStyle(sparkColor(spark.id))
                    .opacity(on ? (fly ? 0 : 0.16 + wave * 0.84) : 0)
                    .scaleEffect(on ? (fly ? 0.2 : 0.45 + wave * 0.6) : 0.2)
                    .offset(x: spark.x * burst, y: spark.y * burst)
            }
        }
        .animation(.easeOut(duration: 0.45), value: on)
        .animation(.easeIn(duration: 0.4), value: fly)
        .accessibilityHidden(true)
    }

    private func sparkColor(_ id: Int) -> Color {
        switch id % 3 {
        case 0: return themeStore.accentGold
        case 1: return themeStore.mainAccentColor
        default: return themeStore.accentPink.opacity(0.9)
        }
    }
}

private struct SplashSpark: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let speed: Double
    let phase: Double
}

#Preview {
    SplashView(onFinished: {})
        .environmentObject(ThemeStore())
}
