import SwiftUI

struct BurningFlameIcon: View {
    var size: CGFloat = 14
    var monochrome: Bool = false
    var color: Color = StreakFireStyle.red

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(monochrome ? Color.white : color)
            .accessibilityHidden(true)
    }
}

struct StreakFireBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let count: Int
    var fontSize: CGFloat = 16
    var flameSize: CGFloat = 14
    var compact: Bool = false
    var celebrateOnIncrease: Bool = true

    @State private var pulse: CGFloat = 1

    var body: some View {
        HStack(spacing: compact ? 3 : 5) {
            BurningFlameIcon(size: flameSize, monochrome: true)
            Text("\(count)")
                .font(themeStore.bold(fontSize))
                .contentTransition(.numericText())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 5 : 7)
        .background(
            Capsule(style: .continuous)
                .fill(StreakFireStyle.red)
        )
        .scaleEffect(pulse)
        .onChange(of: count) { oldValue, newValue in
            guard celebrateOnIncrease, newValue > oldValue else { return }
            Haptics.streak()
            pulse = 1.18
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pulse = 1.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Streak: \(count) days"))
    }
}

enum StreakFireStyle {
    static let red = Color(hex: "#FF3B30")
}

#Preview {
    HStack(spacing: 16) {
        BurningFlameIcon(size: 24)
        StreakFireBadge(count: 7)
    }
    .padding()
    .environmentObject(ThemeStore())
}
