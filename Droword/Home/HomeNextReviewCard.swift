import SwiftUI

/// Карточка «Next Review» на главном: когда повторять нечего, показывает время до
/// следующего повторения и мотивирующую подсказку. Закрывается крестиком.
struct HomeNextReviewCard: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let count: Int
    let date: Date
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeStore.iconCircleFill(colorScheme: colorScheme))
                    .frame(width: 44, height: 44)
                Image(systemName: "timer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Review")
                    .font(themeStore.bold(16))
                    .foregroundStyle(themeStore.mainText)
                Text("\(count) words to review in \(timeUntil(date))")
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                if let hint = longIntervalHint(for: date) {
                    Text(hint)
                        .font(themeStore.regular(12))
                        .foregroundStyle(themeStore.accentGold)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
        .cardDepth(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    private func timeUntil(_ date: Date) -> String {
        let seconds = max(0, date.timeIntervalSince(Date()))
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return String(localized: "\(max(1, minutes)) min")
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(localized: "\(hours) h")
        }
        let days = hours / 24
        return String(localized: "\(days) d")
    }

    private func longIntervalHint(for date: Date) -> LocalizedStringKey? {
        let days = max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
        guard days >= 3 else { return nil }

        let hints: [LocalizedStringKey]
        if days >= 30 {
            hints = [
                "You've mastered these words so well, they need a long break 💪",
                "Your brain locked these in tight. See you in a month!",
                "These words are basically muscle memory now 🧠",
                "Practice paid off — these words are deeply stored"
            ]
        } else if days >= 14 {
            hints = [
                "Great progress — these words are sticking 🎯",
                "Your practice sessions are really paying off",
                "These words are getting into long-term memory 🧩",
                "Almost mastered — just a couple more reviews to go"
            ]
        } else {
            hints = [
                "Words are settling in nicely, keep it up ✨",
                "Spaced repetition is working its magic",
                "You're building strong memory foundations 🌱",
                "Right on track — see you in a few days"
            ]
        }

        let index = abs(date.hashValue) % hints.count
        return hints[index]
    }
}
