import SwiftUI

struct SuggestedWordsIntroView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let onDismiss: () -> Void

    @State private var emojiScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var bulletOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    private var accent: Color { themeStore.accentBlue }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Text("💡")
                    .font(.system(size: 64))
                    .scaleEffect(emojiScale)

                VStack(spacing: 8) {
                    Text("Suggested Words")
                        .font(themeStore.bold(26))
                        .foregroundStyle(themeStore.mainText)

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
                        .font(themeStore.bold(17))
                        .foregroundStyle(.white)
                }
                .duo3DStyle(themeStore.mainAccentColor)
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(themeStore.appBg)
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            Haptics.mediumImpact()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                emojiScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.5)) {
                bulletOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.75)) {
                buttonOpacity = 1.0
            }
        }
    }

    private func bulletRow(icon: String, text: String) -> some View {
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

#Preview {
    SuggestedWordsIntroView(onDismiss: {})
        .environmentObject(ThemeStore())
}
