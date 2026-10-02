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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = EmptyScenePalette(colorScheme)
        ZStack {
            wordCard(width: 126, height: 56, fill: palette.back, line: palette.line, widths: [0.38])
                .offset(x: 18, y: -22)
            wordCard(width: 136, height: 66, fill: palette.front, line: palette.line, widths: [0.48, 0.34])
                .offset(x: -10, y: 18)
        }
        .frame(width: 176, height: 176)
        .accessibilityHidden(true)
    }

    private func wordCard(width: CGFloat, height: CGFloat, fill: Color, line: Color, widths: [CGFloat]) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fill)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(line, style: EmptyStroke.style)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(widths.enumerated()), id: \.offset) { index, portion in
                    Capsule()
                        .fill(line)
                        .frame(width: width * portion, height: 4.5)
                        .opacity(index == 0 ? 1 : 0.7)
                }
            }
            .padding(.leading, 18)
        }
        .frame(width: width, height: height)
    }
}

struct EmptyPracticeArt: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let line = EmptyScenePalette(colorScheme).line
        BulbGlass()
            .stroke(line, style: EmptyStroke.style)
            .frame(width: 120, height: 112)
        .frame(width: 176, height: 176)
        .accessibilityHidden(true)
    }
}

private struct BulbGlass: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - s / 2, y: rect.midY - s / 2)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x / 28 * s, y: origin.y + y / 28 * s)
        }
        var path = Path()
        path.move(to: p(10.5, 19.2))
        path.addCurve(to: p(8.4, 16), control1: p(10.5, 17.9), control2: p(9.4, 17))
        path.addCurve(to: p(6.8, 11.2), control1: p(7.3, 14.7), control2: p(6.8, 13.1))
        path.addCurve(to: p(14, 4), control1: p(6.8, 7.2), control2: p(10, 4))
        path.addCurve(to: p(21.2, 11.2), control1: p(18, 4), control2: p(21.2, 7.2))
        path.addCurve(to: p(19.6, 16), control1: p(21.2, 13.1), control2: p(20.7, 14.7))
        path.addCurve(to: p(17.5, 19.2), control1: p(18.6, 17), control2: p(17.5, 17.9))
        path.closeSubpath()
        path.move(to: p(10.5, 21.6))
        path.addLine(to: p(17.5, 21.6))
        path.move(to: p(11.8, 24.4))
        path.addLine(to: p(16.2, 24.4))
        return path
    }
}

private enum EmptyStroke {
    static let style = StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
}

struct EmptyTagArt: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = EmptyScenePalette(colorScheme)
        ZStack {
            DrawnTagMark(line: palette.line, size: 118)
        }
        .frame(width: 176, height: 176)
        .accessibilityHidden(true)
    }
}

private struct DrawnTagMark: View {
    var line: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            TagOutline()
                .stroke(line, style: EmptyStroke.style)
            Circle()
                .stroke(line, style: EmptyStroke.style)
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(x: size * 0.22)
        }
        .frame(width: size, height: size * 0.52)
        .rotationEffect(.degrees(-8))
    }
}

private struct TagOutline: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 100 * rect.width, y: rect.minY + y / 100 * rect.height)
        }
        var path = Path()
        path.move(to: p(22, 8))
        path.addLine(to: p(84, 8))
        path.addQuadCurve(to: p(96, 28), control: p(96, 8))
        path.addLine(to: p(96, 72))
        path.addQuadCurve(to: p(84, 92), control: p(96, 92))
        path.addLine(to: p(22, 92))
        path.addLine(to: p(4, 50))
        path.closeSubpath()
        return path
    }
}

private struct EmptyScenePalette {
    let back: Color
    let front: Color
    let line: Color

    init(_ scheme: ColorScheme) {
        if scheme == .dark {
            back = Color.white.opacity(0.10)
            front = Color.white.opacity(0.16)
            line = Color.white.opacity(0.28)
        } else {
            back = Color(hex: "#E6E6EA")
            front = Color.white
            line = Color(hex: "#C8C8D0")
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        SoftBlob(color: .blue, size: 120)
        HaloIcon(symbol: "plus", color: .blue, size: 120)
        EmptyDictionaryArt()
        EmptyPracticeArt()
        EmptyTagArt()
    }
    .padding()
    .environmentObject(ThemeStore())
}
