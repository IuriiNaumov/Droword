import SwiftUI

// MARK: - Snowflake shape (SVG-based)
private struct SnowflakeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let s = min(rect.width, rect.height)
        // Scale factor: SVG is 120x120, map to s
        let f = s / 120.0

        var path = Path()

        // 4 main arms (thick lines in SVG)
        let arms: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 60, y: 15), CGPoint(x: 60, y: 105)),   // vertical
            (CGPoint(x: 15, y: 60), CGPoint(x: 105, y: 60)),   // horizontal
            (CGPoint(x: 25, y: 25), CGPoint(x: 95, y: 95)),    // diagonal
            (CGPoint(x: 95, y: 25), CGPoint(x: 25, y: 95)),    // diagonal
        ]

        for arm in arms {
            path.move(to: CGPoint(x: arm.0.x * f, y: arm.0.y * f))
            path.addLine(to: CGPoint(x: arm.1.x * f, y: arm.1.y * f))
        }

        // Branch tips
        let branches: [(CGPoint, CGPoint)] = [
            // Top
            (CGPoint(x: 60, y: 15), CGPoint(x: 52, y: 28)),
            (CGPoint(x: 60, y: 15), CGPoint(x: 68, y: 28)),
            // Right
            (CGPoint(x: 105, y: 60), CGPoint(x: 92, y: 52)),
            (CGPoint(x: 105, y: 60), CGPoint(x: 92, y: 68)),
            // Bottom
            (CGPoint(x: 60, y: 105), CGPoint(x: 52, y: 92)),
            (CGPoint(x: 60, y: 105), CGPoint(x: 68, y: 92)),
            // Left
            (CGPoint(x: 15, y: 60), CGPoint(x: 28, y: 52)),
            (CGPoint(x: 15, y: 60), CGPoint(x: 28, y: 68)),
        ]

        for branch in branches {
            path.move(to: CGPoint(x: branch.0.x * f, y: branch.0.y * f))
            path.addLine(to: CGPoint(x: branch.1.x * f, y: branch.1.y * f))
        }

        // Offset to center
        let offset = CGPoint(x: cx - s / 2, y: cy - s / 2)
        return path.offsetBy(dx: offset.x, dy: offset.y)
    }
}

private struct SnowflakeView: View {
    let size: CGFloat

    var body: some View {
        SnowflakeShape()
            .stroke(Color(red: 0.3, green: 0.65, blue: 1.0), style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
            .frame(width: size, height: size)
    }
}

// MARK: - Sakura flower shape (SVG-based)
private struct SakuraFlower: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // 5 petals
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 1.0, green: 0.56, blue: 0.82))
                    .frame(width: size * 0.233, height: size * 0.367)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            // Center
            Circle()
                .fill(Color(red: 1.0, green: 0.37, blue: 0.69))
                .frame(width: size * 0.167, height: size * 0.167)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Sun shape (SVG-based)
private struct SunView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // 8 ray petals
            ForEach(0..<8, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 1.0, green: 0.847, blue: 0.302))
                    .frame(width: size * 0.2, height: size * 0.433)
                    .offset(y: -size * 0.27)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            // Center
            Circle()
                .fill(Color(red: 0.957, green: 0.639, blue: 0.0))
                .frame(width: size * 0.233, height: size * 0.233)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Autumn leaf shape (SVG-based)
private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let f = s / 120.0
        let ox = rect.midX - s / 2
        let oy = rect.midY - s / 2

        var path = Path()

        // Leaf outline
        path.move(to: CGPoint(x: 60 * f + ox, y: 15 * f + oy))
        path.addCurve(
            to: CGPoint(x: 100 * f + ox, y: 65 * f + oy),
            control1: CGPoint(x: 85 * f + ox, y: 20 * f + oy),
            control2: CGPoint(x: 105 * f + ox, y: 40 * f + oy)
        )
        path.addCurve(
            to: CGPoint(x: 60 * f + ox, y: 105 * f + oy),
            control1: CGPoint(x: 95 * f + ox, y: 90 * f + oy),
            control2: CGPoint(x: 70 * f + ox, y: 105 * f + oy)
        )
        path.addCurve(
            to: CGPoint(x: 20 * f + ox, y: 65 * f + oy),
            control1: CGPoint(x: 50 * f + ox, y: 105 * f + oy),
            control2: CGPoint(x: 25 * f + ox, y: 90 * f + oy)
        )
        path.addCurve(
            to: CGPoint(x: 60 * f + ox, y: 15 * f + oy),
            control1: CGPoint(x: 15 * f + ox, y: 40 * f + oy),
            control2: CGPoint(x: 35 * f + ox, y: 20 * f + oy)
        )
        path.closeSubpath()

        return path
    }
}

private struct LeafVeinsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let f = s / 120.0
        let ox = rect.midX - s / 2
        let oy = rect.midY - s / 2

        var path = Path()

        // Central vein
        path.move(to: CGPoint(x: 60 * f + ox, y: 20 * f + oy))
        path.addLine(to: CGPoint(x: 60 * f + ox, y: 105 * f + oy))

        // Side veins
        let veins: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (60, 40, 80, 55),
            (60, 55, 85, 70),
            (60, 70, 80, 85),
            (60, 40, 40, 55),
            (60, 55, 35, 70),
            (60, 70, 40, 85),
        ]
        for v in veins {
            path.move(to: CGPoint(x: v.0 * f + ox, y: v.1 * f + oy))
            path.addLine(to: CGPoint(x: v.2 * f + ox, y: v.3 * f + oy))
        }

        return path
    }
}

private struct LeafView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            LeafShape()
                .fill(Color(red: 0.788, green: 0.478, blue: 0.169))
            LeafVeinsShape()
                .stroke(Color(red: 0.545, green: 0.29, blue: 0.122), style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

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

    private var season: Season { seasonOverride ?? Season.current }
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

    var body: some View {
        GeometryReader { geo in
            let allShapes = season.shapes.flatMap { shape in
                shape.sizes.map { (shape.emoji, $0) }
            }

            if animated {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let now = timeline.date.timeIntervalSinceReferenceDate

                    ZStack {
                        ForEach(particles) { p in
                            let age = now + p.timeOffset
                            let totalH = geo.size.height + 60
                            let rawY = CGFloat(age) * p.speed
                            let y = ((rawY.truncatingRemainder(dividingBy: totalH) + totalH)
                                .truncatingRemainder(dividingBy: totalH)) - 30
                            let x = p.xFraction * geo.size.width + sin(CGFloat(age) * p.driftSpeed) * p.drift
                            let pick = allShapes[p.shapeIndex % allShapes.count]
                            let flowerSize = pick.1 * (p.size / 20)

                            if season.isSpring {
                                SakuraFlower(size: flowerSize * 2)
                                    .opacity(p.opacity)
                                    .rotationEffect(.degrees(p.rotation + age * 5))
                                    .position(x: x, y: y)
                            } else if season.isWinter {
                                SnowflakeView(size: flowerSize * 2.5)
                                    .opacity(p.opacity)
                                    .rotationEffect(.degrees(p.rotation + age * 5))
                                    .position(x: x, y: y)
                            } else if season.isSummer {
                                SunView(size: flowerSize * 2)
                                    .opacity(p.opacity)
                                    .rotationEffect(.degrees(p.rotation + age * 5))
                                    .position(x: x, y: y)
                            } else {
                                LeafView(size: flowerSize * 2)
                                    .opacity(p.opacity)
                                    .rotationEffect(.degrees(p.rotation + age * 5))
                                    .position(x: x, y: y)
                            }
                        }
                    }
                }
            } else {
                ZStack {
                    ForEach(particles) { p in
                        let pick = allShapes[p.shapeIndex % allShapes.count]
                        let flowerSize = pick.1 * (p.size / 20)

                        Group {
                            if season.isSpring {
                                SakuraFlower(size: flowerSize * 2)
                            } else if season.isWinter {
                                SnowflakeView(size: flowerSize * 2.5)
                            } else if season.isSummer {
                                SunView(size: flowerSize * 2)
                            } else {
                                LeafView(size: flowerSize * 2)
                            }
                        }
                        .opacity(p.opacity)
                        .rotationEffect(.degrees(p.rotation))
                        .position(
                            x: p.xFraction * geo.size.width,
                            y: (p.timeOffset / 50) * geo.size.height
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
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
