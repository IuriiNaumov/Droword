import SwiftUI

enum MilestoneType: Identifiable, Equatable {
    case wordCount(Int)
    case streak(Int)
    case dailyGoal

    var id: String {
        switch self {
        case .wordCount(let n): return "words.\(n)"
        case .streak(let n): return "streak.\(n)"
        case .dailyGoal: return "dailyGoal"
        }
    }

    var emoji: String {
        switch self {
        case .wordCount(let n):
            switch n {
            case ..<25: return "🌱"
            case ..<50: return "🌿"
            case ..<100: return "🌳"
            case ..<200: return "🏆"
            case ..<500: return "👑"
            default: return "💎"
            }
        case .streak(let n):
            switch n {
            case ..<30: return "🔥"
            case ..<100: return "⚡️"
            default: return "🌟"
            }
        case .dailyGoal: return "🎯"
        }
    }

    var title: String {
        switch self {
        case .wordCount(let n): return String(localized: "\(n) words!")
        case .streak(let n): return String(localized: "\(n)-day streak!")
        case .dailyGoal: return String(localized: "Daily goal!")
        }
    }

    func message(wordsCount: Int, daysSinceStart: Int) -> String {
        let wordsPerWeek = daysSinceStart > 0 ? max(1, wordsCount * 7 / daysSinceStart) : wordsCount
        switch self {
        case .wordCount(let n):
            switch n {
            case ..<25:
                if wordsPerWeek >= 10 {
                    return String(localized: "You're learning \(wordsPerWeek) words a week — great pace!")
                }
                return String(localized: "You're off to a great start.")
            case ..<50:
                return String(localized: "You're learning about \(wordsPerWeek) words a week. Keep it up!")
            case ..<100:
                if daysSinceStart <= 30 {
                    return String(localized: "\(n) words in less than a month — impressive!")
                }
                return String(localized: "That's an impressive collection.")
            case ..<200:
                return String(localized: "\(n) words at \(wordsPerWeek) per week. You're becoming a true linguist.")
            case ..<500:
                return String(localized: "Half a thousand words. That's \(wordsPerWeek) words per week on average!")
            default:
                return String(localized: "\(n) words! You've reached legendary status.")
            }
        case .streak(let n):
            switch n {
            case ..<30:
                return String(localized: "A full week of learning! \(wordsCount) words and counting.")
            case ..<100:
                return String(localized: "A whole month. \(wordsCount) words in your dictionary.")
            default:
                return String(localized: "100 days. \(wordsCount) words. Unstoppable.")
            }
        case .dailyGoal:
            return String(localized: "You've hit your target for today. Total: \(wordsCount) words.")
        }
    }
}

struct MilestoneCelebrationView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let milestone: MilestoneType
    var wordsCount: Int = 0
    var daysSinceStart: Int = 0
    let onDismiss: () -> Void

    @State private var emojiScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text(milestone.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(emojiScale)

                VStack(spacing: 8) {
                    Text(milestone.title)
                        .font(themeStore.bold(28))
                        .foregroundColor(themeStore.mainText)

                    Text(milestone.message(wordsCount: wordsCount, daysSinceStart: daysSinceStart))
                        .font(themeStore.regular(16))
                        .foregroundColor(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(themeStore.bold(17))
                        .foregroundColor(.white)
                }
                .duo3DStyle(themeStore.mainAccentColor)
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(themeStore.appBg)
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                emojiScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
                buttonOpacity = 1.0
            }
        }
    }
}
