import SwiftUI


struct QuizProgressHeader: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var session: QuizSessionManager

    let streakScale: CGFloat
    let hasAnswered: Bool
    let isCorrect: Bool
    let reward: (id: Int, text: String)?

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(min(session.answeredCount + 1, session.total))/\(session.total)")
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.secondaryText)

                Spacer()

                if session.currentStreak >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(themeStore.accentRed)
                        Text("\(session.currentStreak)")
                            .font(themeStore.bold(14))
                            .foregroundStyle(themeStore.accentRed)
                    }
                    .scaleEffect(streakScale)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)

            segmentedProgressBar
        }
        .padding(.top, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: session.currentStreak)
        .overlay(alignment: .topTrailing) {
            if let reward {
                FloatingRewardLabel(text: reward.text, color: themeStore.accentGreen)
                    .id(reward.id)
                    .padding(.trailing, 28)
                    .allowsHitTesting(false)
            }
        }
    }

    private var segmentedProgressBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<session.total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(segmentColor(for: index))
                    .frame(height: 6)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.3), value: session.answeredCount)
        .animation(.easeInOut(duration: 0.3), value: hasAnswered)
    }

    private func segmentColor(for index: Int) -> Color {
        if index < session.answeredCount {
            if index < session.orderedResults.count {
                return session.orderedResults[index] ? themeStore.accentGreen : themeStore.accentRed
            }
            return themeStore.accentGreen
        }
        if index == session.answeredCount {
            if hasAnswered {
                return isCorrect ? themeStore.accentGreen : themeStore.accentRed
            }
            return themeStore.secondaryText.opacity(0.35)
        }
        return themeStore.dividerColor.opacity(0.4)
    }
}
