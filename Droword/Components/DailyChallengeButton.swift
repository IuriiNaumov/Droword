import SwiftUI

struct DailyChallengeButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var manager: DailyChallengeManager
    var onOpen: () -> Void

    var body: some View {
        let allDone = manager.allCompleted

        HStack(spacing: 14) {
            Button {
                Haptics.buttonPress()
                onOpen()
            } label: {
                HStack(spacing: 14) {
                    MenuSymbol(systemName: "dumbbell.fill")

                    VStack(alignment: .leading, spacing: 2) {
                        Text(DuoChaosCopy.dailyChallengesTitle())
                            .font(themeStore.bold(16))
                            .foregroundStyle(themeStore.mainText)

                        Text(DuoChaosCopy.dailyChallengesSubtitle(done: manager.completedCount, total: manager.challenges.count))
                            .font(themeStore.regular(13))
                            .foregroundStyle(themeStore.secondaryText)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if allDone {
                Button {
                    Haptics.softTap()
                    withAnimation(.easeOut(duration: 0.25)) {
                        manager.dismissCompletedForToday()
                    }
                } label: {
                    MenuSymbol(
                        systemName: "checkmark",
                        color: themeStore.accentBlue,
                        weight: .semibold
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Done"))
                .accessibilityHint(Text("Hide until tomorrow"))
            }
        }
        .padding(DesignSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
    }
}

#Preview {
    DailyChallengeButton(manager: DailyChallengeManager.shared, onOpen: {})
        .environmentObject(ThemeStore())
        .padding()
}
