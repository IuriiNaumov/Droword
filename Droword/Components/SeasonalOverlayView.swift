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

    var body: some View {
        GeometryReader { geo in
            let allShapes = season.shapes.flatMap { shape in
                shape.sizes.map { (shape.emoji, $0) }
            }

            if shouldAnimate {
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
