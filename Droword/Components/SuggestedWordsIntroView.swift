import SwiftUI

struct SuggestedWordsIntroView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.4
    @State private var textOpacity: Double = 0
    @State private var bulletOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0

    private var accent: Color { themeStore.accentBlue }

    var body: some View {
        ZStack {
            themeStore.appBg.opacity(0.55)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 18) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(themeStore.accentGold)
                    .scaleEffect(iconScale)

                VStack(spacing: 8) {
                    Text("Suggested Words")
                        .font(themeStore.display(22))
                        .foregroundStyle(themeStore.mainText)
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)

                    Text("Smart suggestions just for you")
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)

                VStack(alignment: .leading, spacing: 12) {
                    bulletRow(
                        icon: "brain.head.profile",
                        text: "Based on words you already know"
                    )
                    bulletRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Helps expand your vocabulary naturally"
                    )
                    bulletRow(
                        icon: "plus.circle.fill",
                        text: "Add them to your dictionary with one tap"
                    )
                }
                .opacity(bulletOpacity)

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Got it!")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 360)
            .cleanCard(themeStore: themeStore, cornerRadius: DesignRadius.dialog)
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            Haptics.mediumImpact()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                cardScale = 1
                cardOpacity = 1
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
