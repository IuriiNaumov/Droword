import SwiftUI

struct DailyChallengeButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var manager: DailyChallengeManager

    var body: some View {
        let allDone = manager.allCompleted

        HStack(spacing: 14) {
            Image(systemName: allDone ? "checkmark" : "trophy")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(allDone ? themeStore.accentBlue : themeStore.mainText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(DuoChaosCopy.dailyChallengesTitle())
                    .font(themeStore.bold(16))
                    .foregroundStyle(themeStore.mainText)

                Text(DuoChaosCopy.dailyChallengesSubtitle(done: manager.completedCount, total: manager.challenges.count))
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
            }

            Spacer()

            if allDone {
                ZoomerSticker(text: "Done", rotation: 0, fontSize: 11)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
    }
}

#Preview {
    DailyChallengeButton(manager: DailyChallengeManager.shared)
        .environmentObject(ThemeStore())
        .padding()
}
