import SwiftUI

struct WordsAddedPage: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let count: Int
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.4
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
                    .scaleEffect(iconScale)

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

                Spacer(minLength: 24)

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Continue")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                iconScale = 1
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.15)) {
                textOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
                buttonOpacity = 1
            }
        }
    }
}
