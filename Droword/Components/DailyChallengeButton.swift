import SwiftUI

struct DailyChallengeButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var manager: DailyChallengeManager

    var body: some View {
        let goal = manager.dailyGoalChallenge
        let goalProgress = goal?.progress ?? 0
        let goalDone = goal?.isCompleted ?? false

        HStack(spacing: 12) {
            ZStack {
                if goalDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeStore.accentGreen)
                        .frame(width: 28)
                        .padding(.leading, -16)
                } else {
                    Circle()
                        .stroke(themeStore.accentGreen.opacity(0.2), lineWidth: 5)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: goalProgress)
                        .stroke(themeStore.accentGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalProgress)
                    Text("\(goal?.currentValue ?? 0)")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(themeStore.mainText)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(goalDone ? "Goal reached!" : "Daily goal")
                    .font(themeStore.bold(16))
                    .foregroundColor(themeStore.mainText)
                    .padding(.leading, -16)

                Text(goalDone
                     ? "\(manager.completedCount)/\(manager.challenges.count) challenges done"
                     : "\(goal?.currentValue ?? 0)/\(goal?.targetValue ?? 0) words · \(manager.completedCount)/\(manager.challenges.count) challenges"
                )
                    .font(themeStore.regular(13))
                    .foregroundColor(themeStore.secondaryText)
                    .padding(.leading, -14)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeStore.secondaryText.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }
}

#Preview {
    DailyChallengeButton(manager: DailyChallengeManager.shared)
        .environmentObject(ThemeStore())
        .padding()
}
