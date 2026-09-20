import SwiftUI

struct RoundedStarShape: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.42
    var cornerRadius: CGFloat = 0.12

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let tipCount = points * 2
        var vertices: [CGPoint] = []
        vertices.reserveCapacity(tipCount)

        for i in 0..<tipCount {
            let angle = (-.pi / 2) + (CGFloat(i) * .pi / CGFloat(points))
            let radius = i.isMultiple(of: 2) ? outer : inner
            vertices.append(
                CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
            )
        }

        guard vertices.count >= 3 else { return Path() }

        let radius = outer * cornerRadius
        var path = Path()

        for i in 0..<vertices.count {
            let prev = vertices[(i - 1 + vertices.count) % vertices.count]
            let current = vertices[i]
            let next = vertices[(i + 1) % vertices.count]

            let toPrev = CGPoint(x: prev.x - current.x, y: prev.y - current.y)
            let toNext = CGPoint(x: next.x - current.x, y: next.y - current.y)
            let lenPrev = max(0.0001, hypot(toPrev.x, toPrev.y))
            let lenNext = max(0.0001, hypot(toNext.x, toNext.y))
            let inset = min(radius, lenPrev * 0.35, lenNext * 0.35)

            let p1 = CGPoint(
                x: current.x + toPrev.x / lenPrev * inset,
                y: current.y + toPrev.y / lenPrev * inset
            )
            let p2 = CGPoint(
                x: current.x + toNext.x / lenNext * inset,
                y: current.y + toNext.y / lenNext * inset
            )

            if i == 0 {
                path.move(to: p1)
            } else {
                path.addLine(to: p1)
            }
            path.addQuadCurve(to: p2, control: current)
        }

        path.closeSubpath()
        return path
    }
}

struct GlassProStar: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 24
    var animated: Bool = false

    @Environment(\.scenePhase) private var scenePhase

    private var accent: Color { themeStore.mainAccentColor }

    var body: some View {
        TimelineView(.animation(minimumInterval: animated ? 1.0 / 24.0 : 10.0, paused: !animated || scenePhase != .active)) { context in
            let pulse: CGFloat = {
                guard animated else { return 0.5 }
                let t = context.date.timeIntervalSinceReferenceDate
                return CGFloat(0.5 + 0.5 * sin(t * 2 * .pi / 3.0))
            }()

            ZStack {
                RoundedStarShape()
                    .fill(accent.opacity(0.45 + 0.15 * pulse))
                    .offset(x: size * 0.045, y: size * 0.07)
                    .blur(radius: size * 0.02)

                RoundedStarShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.92),
                                accent.opacity(0.28 + 0.12 * pulse),
                                accent.opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedStarShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.95),
                                accent.opacity(0.7),
                                accent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(2, size * 0.085)
                    )

                RoundedStarShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .mask(
                        RoundedStarShape()
                            .scaleEffect(0.78)
                    )
                    .blendMode(.screen)
                    .opacity(0.85)

                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(x: -size * 0.12, y: -size * 0.18)
                    .blur(radius: 0.4)
            }
            .frame(width: size, height: size)
            .scaleEffect(animated ? 0.96 + 0.04 * pulse : 1)
        }
        .accessibilityLabel(Text("PRO"))
    }
}

#Preview {
    HStack(spacing: 24) {
        GlassProStar(size: 28)
        GlassProStar(size: 64, animated: true)
        GlassProStar(size: 120, animated: true)
    }
    .padding()
    .environmentObject(ThemeStore())
}
