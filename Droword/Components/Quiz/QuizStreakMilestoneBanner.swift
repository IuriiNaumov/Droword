import SwiftUI

struct QuizStreakMilestoneBanner: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let streak: Int

    @State private var appeared = false

    var body: some View {
        AppToastChrome(
            icon: "flame.fill",
            text: DuoChaosCopy.streak(streak),
            tint: themeStore.accentGreen
        )
        .scaleEffect(appeared ? 1 : 0.94)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

#Preview {
    QuizStreakMilestoneBanner(streak: 10)
        .padding()
        .environmentObject(ThemeStore())
}
