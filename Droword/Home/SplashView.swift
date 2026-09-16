import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onFinished: () -> Void

    /// 1 = letters sit as droword, 0 = dro / ord are spread away from w.
    @State private var join: CGFloat = 1
    @State private var wOn = false
    @State private var sidesOn = false
    @State private var wPulse: CGFloat = 1
    @State private var wAppear: CGFloat = 0.4
    @State private var settled = false
    @State private var squeeze = false
    @State private var fly = false

    private let travel: CGFloat = 78

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
                .scaleEffect(wordScale)
                .opacity(fly ? 0 : 1)
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
            splashLetter("d", x: -split, on: sidesOn)
            splashLetter("r", x: -split, on: sidesOn)
            splashLetter("o", x: -split, on: sidesOn)

            Text("w")
                .opacity(wOn ? 1 : 0)
                .scaleEffect(wAppear * wPulse)
                .zIndex(1)

            splashLetter("o", x: split, on: sidesOn)
            splashLetter("r", x: split, on: sidesOn)
            splashLetter("d", x: split, on: sidesOn)
        }
        .font(themeStore.display(48))
        .foregroundStyle(splashText)
    }

    private func splashLetter(_ text: String, x: CGFloat, on: Bool) -> some View {
        Text(text)
            .offset(x: x)
            .opacity(on ? 1 : 0)
            .scaleEffect(on ? 1 : 0.55)
    }

    @MainActor
    private func play() async {
        if reduceMotion {
            wOn = true
            wAppear = 1
            sidesOn = true
            join = 1
            settled = true
            Haptics.softTap()
            try? await Task.sleep(for: .milliseconds(520))
            await finish()
            return
        }

        withAnimation(.spring(response: 0.46, dampingFraction: 0.68)) {
            wOn = true
            wAppear = 1
        }
        Haptics.softTap()
        try? await Task.sleep(for: .milliseconds(380))

        Haptics.splash()
        withAnimation(.spring(response: 0.58, dampingFraction: 0.78)) {
            sidesOn = true
            join = 0
        }

        try? await Task.sleep(for: .milliseconds(720))

        withAnimation(.spring(response: 0.62, dampingFraction: 0.76)) {
            join = 1
        }

        try? await Task.sleep(for: .milliseconds(480))
        Haptics.success()
        withAnimation(.spring(response: 0.34, dampingFraction: 0.55)) {
            wPulse = 1.16
            settled = true
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72).delay(0.08)) {
            wPulse = 1
        }

        try? await Task.sleep(for: .milliseconds(900))
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
