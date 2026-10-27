import SwiftUI

struct SoftBlob: View {
    var color: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.22))
                .frame(width: size * 0.92, height: size * 0.92)
                .offset(x: -size * 0.08, y: size * 0.04)
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: size * 0.72, height: size * 0.72)
                .offset(x: size * 0.16, y: -size * 0.1)
            Circle()
                .fill(color.opacity(0.10))
                .frame(width: size * 0.4, height: size * 0.4)
                .offset(x: size * 0.28, y: size * 0.2)
        }
        .blur(radius: 2)
    }
}

struct DoodleStar: View {
    var color: Color
    var size: CGFloat = 14

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(color)
    }
}

struct SparkleCluster: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 120
    var iconName: String = "sparkles"

    var body: some View {
        ZStack {
            SoftBlob(color: themeStore.mainAccentColor, size: size)

            Image(systemName: iconName)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(themeStore.mainAccentColor)

            DoodleStar(color: themeStore.accentGold, size: size * 0.15)
                .offset(x: size * 0.38, y: -size * 0.30)
            DoodleStar(color: themeStore.mainAccentColor.opacity(0.75), size: size * 0.10)
                .offset(x: -size * 0.38, y: -size * 0.16)
            DoodleStar(color: themeStore.accentPink.opacity(0.9), size: size * 0.08)
                .offset(x: size * 0.34, y: size * 0.24)
            DoodleStar(color: themeStore.accentGold.opacity(0.7), size: size * 0.07)
                .offset(x: -size * 0.28, y: size * 0.28)
        }
        .frame(width: size, height: size * 0.92)
        .accessibilityHidden(true)
    }
}

struct HaloRings: View {
    var color: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.34), color.opacity(0.10), color.opacity(0)],
                        center: .center,
                        startRadius: size * 0.08,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: max(4, size * 0.045))

            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            color.opacity(0.0),
                            color.opacity(0.28),
                            color.opacity(0.0),
                            color.opacity(0.18),
                            color.opacity(0.0)
                        ],
                        center: .center
                    ),
                    lineWidth: max(1, size * 0.012)
                )
                .frame(width: size * 0.78, height: size * 0.78)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.42), color.opacity(0.16), color.opacity(0.08)],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 0,
                        endRadius: size * 0.34
                    )
                )
                .frame(width: size * 0.58, height: size * 0.58)

            Circle()
                .fill(color.opacity(0.16))
                .frame(width: size * 0.34, height: size * 0.34)

            Ellipse()
                .fill(Color.white.opacity(0.38))
                .frame(width: size * 0.22, height: size * 0.08)
                .offset(x: -size * 0.04, y: -size * 0.11)
                .blur(radius: 1.2)
        }
        .frame(width: size, height: size)
    }
}

struct HaloIcon: View {
    var symbol: String
    var color: Color
    var size: CGFloat = 168

    var body: some View {
        ZStack {
            HaloRings(color: color, size: size)
            Image(systemName: symbol)
                .font(.system(size: size * 0.16, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct EmptyDictionaryArt: View {
    var body: some View {
        StickerIcon(art: .cards, size: 150)
    }
}

struct EmptyPracticeArt: View {
    var body: some View {
        StickerBulb(size: 150)
    }
}

#Preview {
    VStack(spacing: 24) {
        SoftBlob(color: .blue, size: 120)
        HaloIcon(symbol: "plus", color: .blue, size: 120)
        EmptyDictionaryArt()
        EmptyPracticeArt()
    }
    .padding()
    .environmentObject(ThemeStore())
}
