import SwiftUI

/// Quiz combo chip: x3 / x5 / ON FIRE — green so it reads as a win, not an error.
struct QuizComboBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let streak: Int
    var scale: CGFloat = 1

    private var label: String {
        if streak >= 7 { return "ON FIRE" }
        return "x\(streak)"
    }

    private var showFlame: Bool { streak >= 3 }

    var body: some View {
        HStack(spacing: 5) {
            if showFlame {
                BurningFlameIcon(
                    size: streak >= 7 ? 15 : 13,
                    monochrome: streak >= 7,
                    color: themeStore.accentGreen
                )
            }
            Text(label)
                .font(themeStore.bold(streak >= 7 ? 13 : 14))
                .tracking(streak >= 7 ? 0.6 : 0)
                .foregroundStyle(streak >= 7 ? Color.white : themeStore.accentGreen)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, streak >= 7 ? 12 : 10)
        .padding(.vertical, 6)
        .background {
            if streak >= 7 {
                Capsule(style: .continuous)
                    .fill(themeStore.accentGreen)
            } else {
                Capsule(style: .continuous)
                    .fill(themeStore.accentGreen.opacity(0.16))
            }
        }
        .scaleEffect(scale)
        .accessibilityLabel(Text("Combo \(streak)"))
    }
}
