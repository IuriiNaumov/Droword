import SwiftUI

struct DailyChallengeButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var manager: DailyChallengeManager
    @Environment(\.colorScheme) private var colorScheme

    private var iconCircleFill: Color {
        themeStore.iconCircleFill(colorScheme: colorScheme)
    }

    var body: some View {
        let allDone = manager.allCompleted

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconCircleFill)
                    .frame(width: 44, height: 44)

                Image(systemName: allDone ? "checkmark" : "trophy.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(allDone ? themeStore.accentGreen : themeStore.iconGold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Challenges")
                    .font(themeStore.bold(16))
                    .foregroundStyle(themeStore.mainText)

                Text("\(manager.completedCount)/\(manager.challenges.count) challenges done")
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(themeStore.accentBlue)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
        .cardDepth(cornerRadius: 16)
    }
}

#Preview {
    DailyChallengeButton(manager: DailyChallengeManager.shared)
        .environmentObject(ThemeStore())
        .padding()
}
