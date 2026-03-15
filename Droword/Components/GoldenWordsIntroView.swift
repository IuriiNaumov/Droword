import SwiftUI

struct GoldenWordsIntroView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let onDismiss: () -> Void

    @State private var emojiScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var bulletOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    private var gold: Color { themeStore.accentGold }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Text("✨")
                    .font(.system(size: 64))
                    .scaleEffect(emojiScale)

                VStack(spacing: 8) {
                    Text("Golden Words")
                        .font(.custom("Poppins-Bold", size: 26))
                        .foregroundColor(.mainBlack)

                    Text("Smart suggestions just for you")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.mainGrey)
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
                        .font(.custom("Poppins-Bold", size: 17))
                        .foregroundColor(.white)
                }
                .duo3DStyle(themeStore.buttonAccent)
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.appBackground)
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
                .foregroundColor(darkerShade(of: gold, by: 0.3))
                .frame(width: 28)

            Text(text)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.mainBlack.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    GoldenWordsIntroView(onDismiss: {})
        .environmentObject(ThemeStore())
}
