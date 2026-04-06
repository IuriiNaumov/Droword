import SwiftUI

struct DailyChallengeDetailView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var manager: DailyChallengeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text("Daily Challenges")
                        .sheetTitle()

                    summaryHeader
                    challengesList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        CloseButtonIcon()
                            .environmentObject(themeStore)
                    }
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(themeStore.accentGreen.opacity(0.15), lineWidth: 8)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: overallProgress)
                    .stroke(themeStore.accentGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: overallProgress)

                VStack(spacing: 0) {
                    Text("\(manager.completedCount)")
                        .font(themeStore.bold(28))
                        .foregroundColor(themeStore.mainText)
                    Text("of \(manager.challenges.count)")
                        .font(themeStore.regular(13))
                        .foregroundColor(themeStore.secondaryText)
                }
            }

            if manager.allCompleted {
                Text("All challenges completed!")
                    .font(themeStore.bold(18))
                    .foregroundColor(themeStore.accentGreen)
            }

            Text("Total completed: \(manager.totalCompleted)")
                .font(themeStore.regular(13))
                .foregroundColor(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }

    private var overallProgress: Double {
        guard !manager.challenges.isEmpty else { return 0 }
        return Double(manager.completedCount) / Double(manager.challenges.count)
    }

    private var challengesList: some View {
        VStack(spacing: 12) {
            ForEach(manager.challenges) { challenge in
                challengeCard(challenge)
            }
        }
    }

    private func challengeCard(_ challenge: DailyChallenge) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(challenge.isCompleted ? themeStore.accentGreen.opacity(0.15) : themeStore.secondaryText.opacity(0.08))
                    .frame(width: 48, height: 48)

                if challenge.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeStore.accentGreen)
                } else {
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeStore.mainText.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(challenge.localizedTitle)
                        .font(themeStore.medium(16))
                        .foregroundColor(challenge.isCompleted ? themeStore.secondaryText : themeStore.mainText)
                        .strikethrough(challenge.isCompleted, color: themeStore.secondaryText)

                    Spacer()
                }

                Text(challenge.localizedDescription)
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeStore.secondaryText.opacity(0.1))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(challenge.isCompleted ? themeStore.accentGreen : themeStore.accentBlue)
                            .frame(width: geo.size.width * challenge.progress, height: 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: challenge.progress)
                    }
                }
                .frame(height: 6)

                Text("\(challenge.currentValue)/\(challenge.targetValue)")
                    .font(themeStore.regular(12))
                    .foregroundColor(themeStore.secondaryText.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }
}
