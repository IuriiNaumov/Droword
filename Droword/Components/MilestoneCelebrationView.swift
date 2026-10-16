import SwiftUI

enum MilestoneType: Identifiable, Equatable {
    case wordCount(Int)
    case streak(Int)
    case dailyGoal
    case badge(id: String, emoji: String, title: String, message: String)

    var id: String {
        switch self {
        case .wordCount(let n): return "words.\(n)"
        case .streak(let n): return "streak.\(n)"
        case .dailyGoal: return "dailyGoal"
        case .badge(let id, _, _, _): return "badge.\(id)"
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
        case .badge(_, let emoji, _, _): return emoji
        }
    }

    var symbol: String {
        switch self {
        case .wordCount: return "text.book.closed"
        case .streak: return "calendar"
        case .dailyGoal: return "flag.checkered"
        case .badge: return "medal"
        }
    }

    var title: String {
        switch self {
        case .wordCount(let n): return String(localized: "\(n) words!")
        case .streak(let n): return String(localized: "\(n)-day streak!")
        case .dailyGoal: return String(localized: "Daily goal!")
        case .badge(_, _, let title, _): return title
        }
    }

    func message(wordsCount: Int, daysSinceStart: Int) -> String {
        switch self {
        case .badge(_, _, _, let message):
            return message
        default:
            break
        }
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
        case .badge:
            return ""
        }
    }
}

struct MilestoneCelebrationView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let milestone: MilestoneType
    var wordsCount: Int = 0
    var daysSinceStart: Int = 0
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.72
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            SoftCoverCentered {
                VStack(spacing: 0) {
                    SoftCoverHero(
                        systemName: milestone.symbol,
                        color: themeStore.iconAccent,
                        iconScale: iconScale
                    )

                    VStack(spacing: 8) {
                        Text(milestone.title)
                            .font(themeStore.display(32))
                            .foregroundStyle(themeStore.mainText)
                            .tracking(-0.4)
                            .multilineTextAlignment(.center)

                        Text(milestone.message(wordsCount: wordsCount, daysSinceStart: daysSinceStart))
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 18)
                    .opacity(textOpacity)
                }
            } footer: {
                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Continue")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
        }
        .onAppear(perform: play)
    }

    private func play() {
        Haptics.encourage()
        guard !reduceMotion else {
            iconScale = 1
            textOpacity = 1
            buttonOpacity = 1
            return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            iconScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.28)) {
            buttonOpacity = 1
        }
    }
}

enum MilestonePreview: String, CaseIterable, Identifiable, Hashable {
    case words10
    case words25
    case words50
    case words100
    case words200
    case words500
    case streak7
    case streak30
    case streak100
    case streak365
    case dailyGoal
    case badge

    var id: String { rawValue }

    var isStreak: Bool {
        switch self {
        case .streak7, .streak30, .streak100, .streak365: return true
        default: return false
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .words10: return "10 words"
        case .words25: return "25 words"
        case .words50: return "50 words"
        case .words100: return "100 words"
        case .words200: return "200 words"
        case .words500: return "500 words"
        case .streak7: return "7-day streak"
        case .streak30: return "30-day streak"
        case .streak100: return "100-day streak"
        case .streak365: return "365-day streak"
        case .dailyGoal: return "Daily goal"
        case .badge: return "Badge unlocked"
        }
    }

    var milestone: MilestoneType {
        switch self {
        case .words10: return .wordCount(10)
        case .words25: return .wordCount(25)
        case .words50: return .wordCount(50)
        case .words100: return .wordCount(100)
        case .words200: return .wordCount(200)
        case .words500: return .wordCount(500)
        case .streak7: return .streak(7)
        case .streak30: return .streak(30)
        case .streak100: return .streak(100)
        case .streak365: return .streak(365)
        case .dailyGoal: return .dailyGoal
        case .badge:
            return .badge(
                id: "quiz.10",
                emoji: "📝",
                title: String(localized: "Badge unlocked!"),
                message: "Quiz Rookie — Complete 10 quizzes"
            )
        }
    }

    var wordsCount: Int {
        switch self {
        case .words10: return 10
        case .words25: return 25
        case .words50: return 50
        case .words100: return 100
        case .words200: return 200
        case .words500: return 500
        case .streak7: return 30
        case .streak30: return 80
        case .streak100: return 140
        case .streak365: return 400
        case .dailyGoal: return 22
        case .badge: return 40
        }
    }

    var daysSinceStart: Int {
        switch self {
        case .words10: return 3
        case .words25: return 10
        case .words50: return 20
        case .words100: return 40
        case .words200: return 80
        case .words500: return 200
        case .streak7: return 10
        case .streak30: return 35
        case .streak100: return 100
        case .streak365: return 365
        case .dailyGoal: return 12
        case .badge: return 20
        }
    }
}

#Preview("Words 10") {
    MilestoneCelebrationView(milestone: .wordCount(10), wordsCount: 10, daysSinceStart: 3, onDismiss: {})
        .environmentObject(ThemeStore())
}

#Preview("Words 50") {
    MilestoneCelebrationView(milestone: .wordCount(50), wordsCount: 50, daysSinceStart: 20, onDismiss: {})
        .environmentObject(ThemeStore())
}

#Preview("Words 100") {
    MilestoneCelebrationView(milestone: .wordCount(100), wordsCount: 100, daysSinceStart: 40, onDismiss: {})
        .environmentObject(ThemeStore())
}

#Preview("Streak 7") {
    MilestoneCelebrationView(milestone: .streak(7), wordsCount: 30, daysSinceStart: 10, onDismiss: {})
        .environmentObject(ThemeStore())
}

#Preview("Streak 30") {
    MilestoneCelebrationView(milestone: .streak(30), wordsCount: 80, daysSinceStart: 35, onDismiss: {})
        .environmentObject(ThemeStore())
}

#Preview("Daily goal") {
    MilestoneCelebrationView(milestone: .dailyGoal, wordsCount: 22, daysSinceStart: 12, onDismiss: {})
        .environmentObject(ThemeStore())
}

#Preview("Badge unlock") {
    MilestoneCelebrationView(
        milestone: .badge(
            id: "quiz.10",
            emoji: "📝",
            title: String(localized: "Badge unlocked!"),
            message: "Quiz Rookie — Complete 10 quizzes"
        ),
        onDismiss: {}
    )
    .environmentObject(ThemeStore())
}
