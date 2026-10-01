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

    var body: some View {
        ZStack {
            HaloRings(color: accent, size: size * 0.88)

            Image(systemName: "sparkle")
                .font(.system(size: size * 0.26, weight: .semibold))
                .foregroundStyle(accent)
                .symbolRenderingMode(.hierarchical)

            ForEach(stars) { star in
                Image(systemName: "sparkle")
                    .font(.system(size: size * star.baseSize, weight: .bold))
                    .foregroundStyle(star.isPink ? themeStore.accentPink : themeStore.accentRed)
                    .offset(x: size * star.x, y: size * star.y)
            }
        }
        .frame(width: size * 1.12, height: size * 1.12)
        .accessibilityLabel(Text("Droword PRO"))
    }
}

struct ProPillBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var prominent: Bool = false

    private var star: CGFloat { prominent ? 14 : 8 }
    private var labelSize: CGFloat { prominent ? 15 : 9 }

    var body: some View {
        HStack(spacing: prominent ? 6 : 3) {
            Image(systemName: prominent ? "sparkles" : "sparkle")
                .font(.system(size: star, weight: .bold))

            Text("PRO")
                .font(themeStore.bold(labelSize))
                .tracking(prominent ? 1.1 : 0.3)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, prominent ? 12 : 6)
        .padding(.vertical, prominent ? 7 : 3)
        .background(Capsule().fill(themeStore.mainAccentColor))
        .accessibilityLabel(Text("PRO"))
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
