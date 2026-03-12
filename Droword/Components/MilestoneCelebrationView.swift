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
        case .wordCount(let n): return "\(n) words!"
        case .streak(let n): return "\(n)-day streak!"
        case .dailyGoal: return "Daily goal!"
        }
    }

    var message: String {
        switch self {
        case .wordCount(let n):
            switch n {
            case ..<25: return "You're off to a great start."
            case ..<50: return "Your vocabulary is growing fast."
            case ..<100: return "That's an impressive collection."
            case ..<200: return "You're becoming a true linguist."
            case ..<500: return "Half a thousand words. Incredible."
            default: return "You've reached legendary status."
            }
        case .streak(let n):
            switch n {
            case ..<30: return "A full week of learning!"
            case ..<100: return "A whole month. Truly dedicated."
            default: return "100 days. Unstoppable."
            }
        case .dailyGoal: return "You've hit your target for today."
        }
    }
}

struct MilestoneCelebrationView: View {
    let milestone: MilestoneType
    let onDismiss: () -> Void

    @State private var emojiScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                Text(milestone.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(emojiScale)

                VStack(spacing: 8) {
                    Text(milestone.title)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.mainBlack)

                    Text(milestone.message)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.mainGrey)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(.custom("Poppins-Bold", size: 17))
                        .foregroundColor(.white)
                }
                .duo3DStyle(Color.accentBlack)
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.appBackground)
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
