import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onFinished: () -> Void

    @State private var join: CGFloat = 1
    @State private var wOn = false
    @State private var sidesOn = false
    @State private var exit: CGFloat = 0

    private let travel: CGFloat = 72

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
