import SwiftUI

struct SuggestedWordsIntroView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.72
    @State private var textOpacity: Double = 0
    @State private var bulletOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    private var accent: Color { themeStore.accentPurple }

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SoftCoverHero(
                            systemName: "wand.and.sparkles",
                            color: accent,
                            iconScale: iconScale
                        )
                        .padding(.top, 24)

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

                        VStack(spacing: 10) {
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
                        .padding(.top, 28)
                        .padding(.bottom, 12)
                        .opacity(bulletOpacity)
                    }
                    .frame(maxWidth: 460)
                    .padding(.horizontal, DesignSpacing.screenInset)
                    .frame(maxWidth: .infinity)
                }

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Got it!")
                        .duo3DStyle(accent)
                }
                .buttonStyle(Duo3DButtonStyle())
                .frame(maxWidth: 460)
                .padding(.horizontal, DesignSpacing.screenInset)
                .padding(.bottom, 12)
                .opacity(buttonOpacity)
            }
        }
        .onAppear(perform: play)
    }

    private func play() {
        Haptics.encourage()
        guard !reduceMotion else {
            iconScale = 1
            textOpacity = 1
            bulletOpacity = 1
            buttonOpacity = 1
            return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
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
    }

    private func bulletRow(icon: String, text: LocalizedStringKey) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)

            Text(text)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.mainText)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .cleanCard(themeStore: themeStore, cornerRadius: themeStore.cardRadius)
    }
}

#Preview("Suggested words intro") {
    SuggestedWordsIntroView(onDismiss: {})
        .environmentObject(ThemeStore())
}
