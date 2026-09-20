import SwiftUI

struct ProBadgeIcon: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 44
    var cornerRadius: CGFloat? = nil

    private var radius: CGFloat { cornerRadius ?? size * 0.28 }
    private var accent: Color { themeStore.mainAccentColor }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(darkerShade(of: accent, by: 0.2))
                .offset(y: max(3, size * 0.06))

            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(accent)

            Text("PRO")
                .font(.system(size: size * 0.28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .tracking(size > 50 ? 1.2 : 0.4)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text("PRO"))
    }
}

struct ProPlusMark: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 120

    private var accent: Color { themeStore.mainAccentColor }
    private let period: Double = 3.0

    private struct TwinkleStar: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let baseSize: CGFloat
        let phase: Double
        let isPink: Bool
    }

    private var stars: [TwinkleStar] {
        [
            TwinkleStar(id: 0, x: 0.40, y: -0.34, baseSize: 0.09, phase: 0.0, isPink: true),
            TwinkleStar(id: 1, x: -0.38, y: -0.18, baseSize: 0.07, phase: 0.35, isPink: false),
            TwinkleStar(id: 2, x: 0.36, y: 0.26, baseSize: 0.08, phase: 0.7, isPink: true),
            TwinkleStar(id: 3, x: -0.32, y: 0.30, baseSize: 0.06, phase: 1.1, isPink: false),
        ]
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: scenePhase != .active)) { context in
            let cycle = (context.date.timeIntervalSinceReferenceDate / period)
                .truncatingRemainder(dividingBy: 1.0)
            let centerPulse = sparkle(cycle: cycle, phase: 0)

            ZStack {
                HaloRings(color: accent, size: size * 0.88)
                    .scaleEffect(0.96 + 0.04 * centerPulse)
                    .opacity(0.85 + 0.15 * centerPulse)

                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.26, weight: .semibold))
                    .foregroundStyle(accent)
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(0.88 + 0.16 * centerPulse)
                    .opacity(0.75 + 0.25 * centerPulse)
                    .rotationEffect(.degrees((centerPulse - 0.5) * 8))
                    .offset(y: (centerPulse - 0.5) * size * 0.03)

                ForEach(stars) { star in
                    let pulse = sparkle(cycle: cycle, phase: star.phase)
                    Image(systemName: "sparkle")
                        .font(.system(size: size * star.baseSize, weight: .bold))
                        .foregroundStyle(star.isPink ? themeStore.accentPink : themeStore.accentRed)
                        .scaleEffect(0.4 + 0.75 * pulse)
                        .opacity(0.2 + 0.8 * pulse)
                        .offset(x: size * star.x, y: size * star.y)
                }
            }
            .frame(width: size * 1.12, height: size * 1.12)
        }
        .accessibilityLabel(Text("Droword PRO"))
    }

    private func sparkle(cycle: Double, phase: Double) -> CGFloat {
        let shifted = (cycle + phase).truncatingRemainder(dividingBy: 1.0)
        return CGFloat(0.5 + 0.5 * sin(shifted * 2 * .pi))
    }
}

struct ProPillBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        Text("PRO")
            .font(themeStore.bold(9))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(themeStore.mainAccentColor)
            )
    }
}

#Preview {
    VStack(spacing: 24) {
        ProPlusMark(size: 132)
        HStack(spacing: 16) {
            ProBadgeIcon()
            ProPillBadge()
        }
    }
    .padding()
    .environmentObject(ThemeStore())
}
