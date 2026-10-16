import SwiftUI

struct WordsAddedPage: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let count: Int
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.72
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            SoftCoverCentered {
                VStack(spacing: 0) {
                    SoftCoverHero(
                        systemName: "checkmark.circle",
                        color: themeStore.iconAccent,
                        iconScale: iconScale
                    )

                    VStack(spacing: 8) {
                        Text("All done!")
                            .font(themeStore.display(32))
                            .foregroundStyle(themeStore.mainText)
                            .tracking(-0.4)
                            .multilineTextAlignment(.center)

                        Text("\(count) words added to your dictionary")
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 18)
                    .opacity(textOpacity)
                }
            } footer: {
                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Continue")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
        }
        .onAppear(perform: play)
    }

    private func play() {
        Haptics.success()
        guard !reduceMotion else {
            iconScale = 1
            textOpacity = 1
            buttonOpacity = 1
            return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            iconScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.28)) {
            buttonOpacity = 1
        }
    }
}
