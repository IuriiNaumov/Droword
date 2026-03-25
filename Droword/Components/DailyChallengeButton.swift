import SwiftUI

// MARK: - Compact button for HomeView

struct DailyChallengeButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var manager: DailyChallengeManager

    var body: some View {
        let goal = manager.dailyGoalChallenge
        let goalProgress = goal?.progress ?? 0
        let goalDone = goal?.isCompleted ?? false

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(themeStore.accentGreen.opacity(0.2), lineWidth: 5)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: goalProgress)
                    .stroke(themeStore.accentGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalProgress)
                if goalDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeStore.accentGreen)
                } else {
                    Text("\(goal?.currentValue ?? 0)")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(themeStore.mainText)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(goalDone ? "Goal reached!" : "Daily goal")
                    .font(.custom("Poppins-Bold", size: 15))
                    .foregroundColor(themeStore.mainText)

                Text(goalDone
                     ? "\(manager.completedCount)/\(manager.challenges.count) challenges done"
                     : "\(goal?.currentValue ?? 0)/\(goal?.targetValue ?? 0) words · \(manager.completedCount)/\(manager.challenges.count) challenges"
                )
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(themeStore.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeStore.secondaryText.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
                )
        )
    }
}

#Preview {
    DailyChallengeButton(manager: DailyChallengeManager.shared)
        .environmentObject(ThemeStore())
        .padding()
}
