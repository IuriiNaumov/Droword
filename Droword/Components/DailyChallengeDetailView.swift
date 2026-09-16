import SwiftUI

struct DailyChallengeDetailView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
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
                    HomeVisibilityHint(message: "You can hide Daily Challenges from Home whenever you want.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(themeStore.accentBlue.opacity(0.15), lineWidth: 8)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: overallProgress)
                    .stroke(themeStore.accentBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: overallProgress)

                VStack(spacing: 0) {
                    Text("\(manager.completedCount)")
                        .font(themeStore.bold(28))
                        .foregroundStyle(themeStore.mainText)
                    Text("of \(manager.challenges.count)")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
            }

            if manager.allCompleted {
                Text("All challenges completed!")
                    .font(themeStore.bold(18))
                    .foregroundStyle(themeStore.accentBlue)
            }

            Text("Total completed: \(manager.totalCompleted)")
                .font(themeStore.regular(13))
                .foregroundStyle(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        .cardDepth(cornerRadius: 20)
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
            Image(systemName: challenge.isCompleted ? "checkmark" : challenge.type.icon)
                .font(.system(size: 20, weight: challenge.isCompleted ? .bold : .regular))
                .foregroundStyle(challenge.isCompleted ? themeStore.accentBlue : themeStore.mainText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(challenge.localizedTitle)
                        .font(themeStore.medium(16))
                        .foregroundStyle(challenge.isCompleted ? themeStore.secondaryText : themeStore.mainText)
                        .strikethrough(challenge.isCompleted, color: themeStore.secondaryText)

                    Spacer()
                }

                Text(challenge.localizedDescription)
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeStore.secondaryText.opacity(0.1))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeStore.accentBlue.opacity(challenge.isCompleted ? 1 : 0.55))
                            .frame(width: geo.size.width * challenge.progress, height: 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: challenge.progress)
                    }
                }
                .frame(height: 6)

                Text("\(challenge.currentValue)/\(challenge.targetValue)")
                    .font(themeStore.regular(12))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.card))
    }
}
