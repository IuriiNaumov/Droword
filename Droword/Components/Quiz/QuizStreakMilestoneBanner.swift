import SwiftUI

struct QuizStreakMilestoneBanner: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let streak: Int

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 8) {
            BurningFlameIcon(size: 16, monochrome: true)
            Text(DuoChaosCopy.streak(streak))
                .font(themeStore.bold(14))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            Capsule(style: .continuous)
                .fill(StreakFireStyle.red)
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
