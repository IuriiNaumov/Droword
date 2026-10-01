import SwiftUI

struct QuizComboBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let streak: Int
    var scale: CGFloat = 1

    @State private var ring = false

    private var label: String {
        if streak >= 7 { return DuoChaosCopy.comboOnFire() }
        return "x\(streak)"
    }

    private var showFlame: Bool { streak >= 3 }

    var body: some View {
        HStack(spacing: 5) {
            if showFlame {
                BurningFlameIcon(
                    size: streak >= 7 ? 15 : 13,
                    monochrome: streak >= 7
                )
            }
            Text(label)
                .font(themeStore.bold(streak >= 7 ? 13 : 14))
                .tracking(streak >= 7 ? 0.6 : 0)
                .foregroundStyle(streak >= 7 ? Color.white : StreakFireStyle.red)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, streak >= 7 ? 12 : 10)
        .padding(.vertical, 6)
        .background {
            if streak >= 7 {
                Capsule(style: .continuous)
                    .fill(StreakFireStyle.red)
            } else {
                Capsule(style: .continuous)
                    .fill(StreakFireStyle.red.opacity(0.16))
            }
        }
        .overlay {
            if streak >= 7 {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.95), lineWidth: 1.5)
                    .scaleEffect(ring ? 1.6 : 0.82)
                    .opacity(ring ? 0 : 0.95)
            }
        }
        .scaleEffect(scale)
        .onAppear {
            guard streak >= 7 else { return }
            withAnimation(.easeOut(duration: 0.48)) {
                ring = true
            }
        }
        .accessibilityLabel(Text("Combo \(streak)"))
    }
}

#Preview {
    QuizComboBadge(streak: 5)
        .padding()
        .environmentObject(ThemeStore())
}
