import SwiftUI

enum Season {
    case winter, spring, summer, fall

    var shapes: [SeasonShape] {
        switch self {
        case .spring: return [
            .init(emoji: "🌸", sizes: [18, 14, 22, 12, 16, 20, 10, 15]),
            .init(emoji: "🌷", sizes: [14, 18, 12, 16, 20, 13]),
        ]
        case .summer: return [
            .init(emoji: "☀️", sizes: [16, 12, 20, 14, 18, 10]),
            .init(emoji: "🌻", sizes: [14, 18, 12, 16, 20, 13]),
        ]
        case .fall: return [
            .init(emoji: "🍂", sizes: [16, 20, 14, 18, 12, 22, 10]),
            .init(emoji: "🍁", sizes: [14, 18, 12, 20, 16, 13]),
        ]
        case .winter: return [
            .init(emoji: "❄️", sizes: [16, 12, 20, 14, 18, 22, 10]),
            .init(emoji: "✨", sizes: [10, 14, 12, 16, 18, 13]),
        ]
        }
    }

    var isSpring: Bool { self == .spring }
    var isWinter: Bool { self == .winter }
    var isSummer: Bool { self == .summer }
    var isFall: Bool { self == .fall }

    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2:  return .winter
        case 3, 4, 5:   return .spring
        case 6, 7, 8:   return .summer
        default:         return .fall
        }
    }
}

struct SeasonShape {
    let emoji: String
    let sizes: [CGFloat]
}

private struct Particle: Identifiable {
    let id: Int
    let xFraction: CGFloat
    let speed: CGFloat
    let drift: CGFloat
    let driftSpeed: CGFloat
    let size: CGFloat
    let opacity: Double
    let timeOffset: Double
    let rotation: Double
    let shapeIndex: Int
}

struct SeasonalOverlayView: View {
    var animated: Bool = true
    var seasonOverride: Season? = nil
    @Environment(\.scenePhase) private var scenePhase

    private var season: Season { seasonOverride ?? Season.current }
    private var shouldAnimate: Bool { animated && scenePhase == .active }
    private let particles: [Particle] = {
        (0..<20).map { i in
            var h = UInt64(i) &* 2654435761
            func next() -> Double {
                h = h ^ (h >> 16); h = h &* 0x45d9f3b; h = h ^ (h >> 16)
                return Double(h % 10000) / 10000.0
            }
            return Particle(
                id: i,
                xFraction: CGFloat(next()),
                speed: CGFloat(10 + next() * 18),
                drift: CGFloat(12 + next() * 20),
                driftSpeed: CGFloat(0.3 + next() * 0.6),
                size: CGFloat(14 + next() * 12),
                opacity: 0.15 + next() * 0.2,
                timeOffset: next() * 50,
                rotation: next() * 360,
                shapeIndex: Int(next() * 100)
            )
        }
    }()

    private static let springColor = Color(red: 1.0, green: 0.56, blue: 0.82)
    private static let springCenter = Color(red: 1.0, green: 0.37, blue: 0.69)
    private static let winterColor = Color(red: 0.3, green: 0.65, blue: 1.0)
    private static let summerPetal = Color(red: 1.0, green: 0.847, blue: 0.302)
    private static let summerCenter = Color(red: 0.957, green: 0.639, blue: 0.0)
    private static let leafFill = Color(red: 0.788, green: 0.478, blue: 0.169)

    var body: some View {
        GeometryReader { geo in
            let allShapes = season.shapes.flatMap { shape in
                shape.sizes.map { (shape.emoji, $0) }
            }

            if shouldAnimate {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let now = timeline.date.timeIntervalSinceReferenceDate

                    Canvas { context, size in
                        for p in particles {
                            let age = now + p.timeOffset
                            let totalH = size.height + 60
                            let rawY = CGFloat(age) * p.speed
                            let y = ((rawY.truncatingRemainder(dividingBy: totalH) + totalH)
                                .truncatingRemainder(dividingBy: totalH)) - 30
                            let x = p.xFraction * size.width + sin(CGFloat(age) * p.driftSpeed) * p.drift
                            let pick = allShapes[p.shapeIndex % allShapes.count]
                            let s = pick.1 * (p.size / 20) * 2
                            let angle = Angle.degrees(p.rotation + age * 5)

                            var ctx = context
                            ctx.opacity = p.opacity
                            ctx.translateBy(x: x, y: y)
                            ctx.rotate(by: angle)

                            drawParticleShape(in: &ctx, season: season, size: s)
                        }
                    }
                }
            } else {
                Canvas { context, size in
                    for p in particles {
                        let pick = allShapes[p.shapeIndex % allShapes.count]
                        let s = pick.1 * (p.size / 20) * 2
                        let x = p.xFraction * size.width
                        let y = (p.timeOffset / 50) * size.height

                        var ctx = context
                        ctx.opacity = p.opacity
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: .degrees(p.rotation))

                        drawParticleShape(in: &ctx, season: season, size: s)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawParticleShape(in context: inout GraphicsContext, season: Season, size: CGFloat) {
        switch season {
        case .spring:
            for i in 0..<5 {
                let petalW = size * 0.233
                let petalH = size * 0.367
                let offsetY = -size * 0.25
                var petal = context
                petal.rotate(by: .degrees(Double(i) * 72))
                petal.translateBy(x: 0, y: offsetY)
                let rect = CGRect(x: -petalW / 2, y: -petalH / 2, width: petalW, height: petalH)
                petal.fill(Path(ellipseIn: rect), with: .color(Self.springColor))
            }
            let cR = size * 0.167 / 2
            context.fill(Path(ellipseIn: CGRect(x: -cR, y: -cR, width: cR * 2, height: cR * 2)), with: .color(Self.springCenter))

        case .winter:
            let s = size * 1.25
            let f = s / 120.0
            let lw = s * 0.05
            let arms: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (60, 15, 60, 105), (15, 60, 105, 60),
                (25, 25, 95, 95), (95, 25, 25, 95),
            ]
            let branches: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (60, 15, 52, 28), (60, 15, 68, 28),
                (105, 60, 92, 52), (105, 60, 92, 68),
                (60, 105, 52, 92), (60, 105, 68, 92),
                (15, 60, 28, 52), (15, 60, 28, 68),
            ]
            var path = Path()
            for a in arms {
                path.move(to: CGPoint(x: a.0 * f - s / 2, y: a.1 * f - s / 2))
                path.addLine(to: CGPoint(x: a.2 * f - s / 2, y: a.3 * f - s / 2))
            }
            for b in branches {
                path.move(to: CGPoint(x: b.0 * f - s / 2, y: b.1 * f - s / 2))
                path.addLine(to: CGPoint(x: b.2 * f - s / 2, y: b.3 * f - s / 2))
            }
            context.stroke(path, with: .color(Self.winterColor), style: StrokeStyle(lineWidth: lw, lineCap: .round))

        case .summer:
            for i in 0..<8 {
                let petalW = size * 0.2
                let petalH = size * 0.433
                let offsetY = -size * 0.27
                var petal = context
                petal.rotate(by: .degrees(Double(i) * 45))
                petal.translateBy(x: 0, y: offsetY)
                let rect = CGRect(x: -petalW / 2, y: -petalH / 2, width: petalW, height: petalH)
                petal.fill(Path(ellipseIn: rect), with: .color(Self.summerPetal))
            }
            let cR = size * 0.233 / 2
            context.fill(Path(ellipseIn: CGRect(x: -cR, y: -cR, width: cR * 2, height: cR * 2)), with: .color(Self.summerCenter))

        case .fall:
            let f = size / 120.0
            var leafPath = Path()
            leafPath.move(to: CGPoint(x: 0, y: -45 * f))
            leafPath.addCurve(to: CGPoint(x: 40 * f, y: 5 * f),
                              control1: CGPoint(x: 25 * f, y: -40 * f),
                              control2: CGPoint(x: 45 * f, y: -20 * f))
            leafPath.addCurve(to: CGPoint(x: 0, y: 45 * f),
                              control1: CGPoint(x: 35 * f, y: 30 * f),
                              control2: CGPoint(x: 10 * f, y: 45 * f))
            leafPath.addCurve(to: CGPoint(x: -40 * f, y: 5 * f),
                              control1: CGPoint(x: -10 * f, y: 45 * f),
                              control2: CGPoint(x: -35 * f, y: 30 * f))
            leafPath.addCurve(to: CGPoint(x: 0, y: -45 * f),
                              control1: CGPoint(x: -45 * f, y: -20 * f),
                              control2: CGPoint(x: -25 * f, y: -40 * f))
            leafPath.closeSubpath()
            context.fill(leafPath, with: .color(Self.leafFill))
        }
    }
}

#Preview("Spring") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(animated: false, seasonOverride: .spring)
    }
    .ignoresSafeArea()
}

#Preview("Summer") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(animated: false, seasonOverride: .summer)
    }
    .ignoresSafeArea()
}

#Preview("Fall") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(animated: false, seasonOverride: .fall)
    }
    .ignoresSafeArea()
}

#Preview("Winter") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(animated: false, seasonOverride: .winter)
    }
    .ignoresSafeArea()
}
