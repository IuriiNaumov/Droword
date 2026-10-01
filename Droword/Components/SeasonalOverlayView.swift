import SwiftUI

enum Season: String, CaseIterable, Identifiable {
    case spring, summer, fall, winter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spring: return String(localized: "Spring")
        case .summer: return String(localized: "Summer")
        case .fall: return String(localized: "Fall")
        case .winter: return String(localized: "Winter")
        }
    }

    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2:  return .winter
        case 3, 4, 5:   return .spring
        case 6, 7, 8:   return .summer
        default:         return .fall
        }
    }

    static func selection(from raw: String) -> [Season] {
        let picked = Set(raw.split(separator: ",").compactMap { Season(rawValue: String($0)) })
        return picked.isEmpty ? [current] : allCases.filter(picked.contains)
    }

    static func storageValue(_ seasons: Set<Season>) -> String {
        allCases.filter(seasons.contains).map(\.rawValue).joined(separator: ",")
    }
}

private struct Particle {
    let r: [Double]
}

private enum ParticleKind {
    case maple, birch, petal, blossom, flake, snow, seed, glow
}

private struct ParticleLook {
    var kind: ParticleKind
    var size: CGFloat
    var speed: CGFloat
    var drift: CGFloat
    var sway: Double
    var spin: Double
    var flip: Double
    var opacity: Double
    var tint: Int
}

struct SeasonalOverlayView: View {
    var animated: Bool = true
    var seasonOverride: Season? = nil
    @AppStorage(AppStorageKeys.seasonalEffectsSelection) private var selectionRaw: String = ""
    @Environment(\.scenePhase) private var scenePhase

    private var seasons: [Season] {
        if let seasonOverride { return [seasonOverride] }
        return Season.selection(from: selectionRaw)
    }

    private var shouldAnimate: Bool { animated && scenePhase == .active }

    private static let particles: [Particle] = (0..<26).map { i in
        var h = UInt64(i + 1) &* 2654435761
        func next() -> Double {
            h = h ^ (h >> 16); h = h &* 0x45d9f3b; h = h ^ (h >> 16)
            return Double(h % 10000) / 10000.0
        }
        return Particle(r: (0..<8).map { _ in next() })
    }

    var body: some View {
        Group {
            if shouldAnimate {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    canvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                canvas(time: nil)
            }
        }
        .allowsHitTesting(false)
    }

    private func canvas(time: Double?) -> some View {
        let seasons = seasons
        return Canvas { context, size in
            for (index, particle) in Self.particles.enumerated() {
                let season = seasons[index % seasons.count]
                draw(particle, look: Self.look(for: season, r: particle.r), time: time, in: context, size: size)
            }
        }
    }

    private static func look(for season: Season, r: [Double]) -> ParticleLook {
        switch season {
        case .fall:
            return ParticleLook(
                kind: r[2] < 0.55 ? .maple : .birch,
                size: 22 + r[3] * 16,
                speed: 30 + r[4] * 30,
                drift: 22 + r[5] * 26,
                sway: 0.6 + r[6] * 0.7,
                spin: (r[7] - 0.5) * 120,
                flip: 1.2 + r[6] * 1.6,
                opacity: 0.5 + r[3] * 0.3,
                tint: Int(r[5] * 5)
            )
        case .spring:
            let blossom = r[2] >= 0.75
            return ParticleLook(
                kind: blossom ? .blossom : .petal,
                size: blossom ? 24 + r[3] * 10 : 16 + r[3] * 9,
                speed: 20 + r[4] * 20,
                drift: 28 + r[5] * 24,
                sway: 0.5 + r[6] * 0.6,
                spin: (r[7] - 0.5) * (blossom ? 60 : 160),
                flip: blossom ? 0 : 1.5 + r[6] * 2,
                opacity: 0.75 + r[3] * 0.25,
                tint: Int(r[5] * 3)
            )
        case .winter:
            let flake = r[2] < 0.45
            return ParticleLook(
                kind: flake ? .flake : .snow,
                size: flake ? 14 + r[3] * 12 : 3 + r[3] * 5,
                speed: flake ? 18 + r[4] * 16 : 24 + r[4] * 26,
                drift: 10 + r[5] * 16,
                sway: 0.4 + r[6] * 0.5,
                spin: flake ? (r[7] - 0.5) * 40 : 0,
                flip: 0,
                opacity: flake ? 0.5 + r[3] * 0.3 : 0.35 + r[3] * 0.35,
                tint: 0
            )
        case .summer:
            let seed = r[2] < 0.6
            return ParticleLook(
                kind: seed ? .seed : .glow,
                size: seed ? 22 + r[3] * 12 : 18 + r[3] * 30,
                speed: seed ? -(8 + r[4] * 10) : -(3 + r[4] * 5),
                drift: seed ? 26 + r[5] * 24 : 14,
                sway: seed ? 0.35 + r[6] * 0.4 : 0.2,
                spin: seed ? (r[7] - 0.5) * 30 : 0,
                flip: 0,
                opacity: seed ? 0.55 + r[3] * 0.3 : 0.14 + r[3] * 0.14,
                tint: 0
            )
        }
    }

    private func draw(_ p: Particle, look: ParticleLook, time: Double?, in context: GraphicsContext, size: CGSize) {
        let r = p.r
        let age = (time ?? 0) + r[0] * 60
        let margin = look.size * 1.5 + 20
        let x: CGFloat
        let y: CGFloat
        if time != nil {
            let span = size.height + margin * 2
            let raw = CGFloat(age) * look.speed + CGFloat(r[1]) * span
            y = (raw.truncatingRemainder(dividingBy: span) + span).truncatingRemainder(dividingBy: span) - margin
            x = CGFloat(r[0]) * size.width + CGFloat(sin(age * look.sway + r[6] * 6)) * look.drift
        } else {
            y = CGFloat(r[1]) * size.height
            x = CGFloat(r[0]) * size.width
        }

        var ctx = context
        ctx.opacity = look.opacity
        if look.kind == .glow {
            ctx.opacity *= 0.7 + 0.3 * sin(age * 0.8 + r[4] * 6)
        }
        ctx.translateBy(x: x, y: y)
        if look.spin != 0 || look.kind == .maple || look.kind == .birch || look.kind == .petal {
            ctx.rotate(by: .degrees(r[7] * 360 + age * look.spin))
        }
        if look.flip > 0 {
            let c = cos(age * look.flip + r[2] * 6)
            let scale = c < 0 ? min(-0.18, c) : max(0.18, c)
            ctx.scaleBy(x: CGFloat(scale), y: 1)
        }

        switch look.kind {
        case .maple: drawMaple(in: ctx, size: look.size, tint: look.tint)
        case .birch: drawBirch(in: ctx, size: look.size, tint: look.tint)
        case .petal: drawPetal(in: ctx, height: look.size, tint: look.tint)
        case .blossom: drawBlossom(in: ctx, size: look.size, tint: look.tint)
        case .flake: drawFlake(in: ctx, size: look.size)
        case .snow: drawSnow(in: ctx, size: look.size)
        case .seed: drawSeed(in: ctx, size: look.size)
        case .glow: drawGlow(in: ctx, size: look.size)
        }
    }

    private static let leafTints: [(Color, Color)] = [
        (Color(hex: "#FFA94D"), Color(hex: "#E8590C")),
        (Color(hex: "#FF6B6B"), Color(hex: "#C92A2A")),
        (Color(hex: "#FFD43B"), Color(hex: "#F08C00")),
        (Color(hex: "#F76707"), Color(hex: "#A33A0B")),
        (Color(hex: "#C08552"), Color(hex: "#7A4A22")),
    ]

    private static let mapleHalf: [CGPoint] = [
        CGPoint(x: 0.10, y: -0.70), CGPoint(x: 0.25, y: -0.78), CGPoint(x: 0.21, y: -0.42),
        CGPoint(x: 0.52, y: -0.70), CGPoint(x: 0.50, y: -0.48), CGPoint(x: 0.80, y: -0.46),
        CGPoint(x: 0.66, y: -0.28), CGPoint(x: 0.94, y: -0.10), CGPoint(x: 0.62, y: 0.00),
        CGPoint(x: 0.68, y: 0.18), CGPoint(x: 0.37, y: 0.13), CGPoint(x: 0.43, y: 0.42),
        CGPoint(x: 0.17, y: 0.25), CGPoint(x: 0.05, y: 0.40),
    ]

    private func leafShading(size: CGFloat, tint: Int) -> (GraphicsContext.Shading, Color) {
        let colors = Self.leafTints[tint % Self.leafTints.count]
        let half = size / 2
        return (
            .linearGradient(
                Gradient(colors: [colors.0, colors.1]),
                startPoint: CGPoint(x: -half, y: -half),
                endPoint: CGPoint(x: half, y: half)
            ),
            colors.1
        )
    }

    private func drawMaple(in ctx: GraphicsContext, size: CGFloat, tint: Int) {
        let u = size / 2
        func pt(_ p: CGPoint, mirror: Bool = false) -> CGPoint {
            CGPoint(x: (mirror ? -p.x : p.x) * u, y: p.y * u)
        }
        var leaf = Path()
        leaf.move(to: CGPoint(x: 0, y: -u))
        Self.mapleHalf.forEach { leaf.addLine(to: pt($0)) }
        Self.mapleHalf.reversed().forEach { leaf.addLine(to: pt($0, mirror: true)) }
        leaf.closeSubpath()

        let (fill, dark) = leafShading(size: size, tint: tint)
        ctx.fill(leaf, with: fill)

        let base = CGPoint(x: 0, y: 0.32 * u)
        var veins = Path()
        for tip in [CGPoint(x: 0, y: -0.85), CGPoint(x: 0.78, y: -0.10), CGPoint(x: 0.44, y: -0.60), CGPoint(x: 0.34, y: 0.34)] {
            veins.move(to: base)
            veins.addLine(to: pt(tip))
            if tip.x != 0 {
                veins.move(to: base)
                veins.addLine(to: pt(tip, mirror: true))
            }
        }
        ctx.stroke(veins, with: .color(dark.opacity(0.55)), style: StrokeStyle(lineWidth: max(0.6, size * 0.03), lineCap: .round))

        var stem = Path()
        stem.move(to: CGPoint(x: 0, y: 0.36 * u))
        stem.addQuadCurve(to: CGPoint(x: 0.08 * u, y: 0.98 * u), control: CGPoint(x: -0.04 * u, y: 0.7 * u))
        ctx.stroke(stem, with: .color(dark), style: StrokeStyle(lineWidth: max(0.8, size * 0.05), lineCap: .round))
    }

    private func drawBirch(in ctx: GraphicsContext, size: CGFloat, tint: Int) {
        let u = size / 2
        var leaf = Path()
        leaf.move(to: CGPoint(x: 0, y: -u))
        leaf.addCurve(to: CGPoint(x: 0, y: 0.62 * u),
                      control1: CGPoint(x: 0.58 * u, y: -0.55 * u),
                      control2: CGPoint(x: 0.62 * u, y: 0.45 * u))
        leaf.addCurve(to: CGPoint(x: 0, y: -u),
                      control1: CGPoint(x: -0.62 * u, y: 0.45 * u),
                      control2: CGPoint(x: -0.58 * u, y: -0.55 * u))
        leaf.closeSubpath()

        let (fill, dark) = leafShading(size: size, tint: tint + 2)
        ctx.fill(leaf, with: fill)

        var veins = Path()
        veins.move(to: CGPoint(x: 0, y: 0.62 * u))
        veins.addLine(to: CGPoint(x: 0, y: -0.86 * u))
        for k in 0..<4 {
            let y = (0.38 - Double(k) * 0.3) * u
            let reach = (0.36 - Double(k) * 0.05) * u
            for side in [-1.0, 1.0] {
                veins.move(to: CGPoint(x: 0, y: y))
                veins.addQuadCurve(to: CGPoint(x: side * reach, y: y - 0.26 * u),
                                   control: CGPoint(x: side * reach * 0.5, y: y - 0.04 * u))
            }
        }
        ctx.stroke(veins, with: .color(dark.opacity(0.5)), style: StrokeStyle(lineWidth: max(0.6, size * 0.028), lineCap: .round))

        var stem = Path()
        stem.move(to: CGPoint(x: 0, y: 0.6 * u))
        stem.addLine(to: CGPoint(x: 0.03 * u, y: 0.98 * u))
        ctx.stroke(stem, with: .color(dark), style: StrokeStyle(lineWidth: max(0.8, size * 0.05), lineCap: .round))
    }

    private static let petalTints: [(Color, Color)] = [
        (Color(hex: "#FFDEEB"), Color(hex: "#F783AC")),
        (Color(hex: "#FFD0E1"), Color(hex: "#F06595")),
        (Color(hex: "#FFE8F0"), Color(hex: "#F49AC1")),
    ]

    private func petalPath(height: CGFloat) -> Path {
        let u = height / 2
        var petal = Path()
        petal.move(to: CGPoint(x: 0, y: 0.9 * u))
        petal.addCurve(to: CGPoint(x: 0.34 * u, y: -0.86 * u),
                       control1: CGPoint(x: 0.44 * u, y: 0.6 * u),
                       control2: CGPoint(x: 0.64 * u, y: -0.4 * u))
        petal.addQuadCurve(to: CGPoint(x: 0, y: -0.64 * u), control: CGPoint(x: 0.12 * u, y: -0.92 * u))
        petal.addQuadCurve(to: CGPoint(x: -0.34 * u, y: -0.86 * u), control: CGPoint(x: -0.12 * u, y: -0.92 * u))
        petal.addCurve(to: CGPoint(x: 0, y: 0.9 * u),
                       control1: CGPoint(x: -0.64 * u, y: -0.4 * u),
                       control2: CGPoint(x: -0.44 * u, y: 0.6 * u))
        petal.closeSubpath()
        return petal
    }

    private func drawPetal(in ctx: GraphicsContext, height: CGFloat, tint: Int) {
        let colors = Self.petalTints[tint % Self.petalTints.count]
        let u = height / 2
        ctx.fill(
            petalPath(height: height),
            with: .linearGradient(
                Gradient(colors: [colors.0, colors.1]),
                startPoint: CGPoint(x: 0, y: -u),
                endPoint: CGPoint(x: 0, y: u)
            )
        )
        var crease = Path()
        crease.move(to: CGPoint(x: 0, y: 0.7 * u))
        crease.addLine(to: CGPoint(x: 0, y: -0.3 * u))
        ctx.stroke(crease, with: .color(colors.1.opacity(0.5)), lineWidth: max(0.5, height * 0.03))
    }

    private func drawBlossom(in ctx: GraphicsContext, size: CGFloat, tint: Int) {
        let petalHeight = size * 0.52
        for i in 0..<5 {
            var petal = ctx
            petal.rotate(by: .degrees(Double(i) * 72))
            petal.translateBy(x: 0, y: -petalHeight * 0.42)
            drawPetal(in: petal, height: petalHeight, tint: tint)
        }
        let core = size * 0.09
        ctx.fill(Path(ellipseIn: CGRect(x: -core, y: -core, width: core * 2, height: core * 2)),
                 with: .color(Color(hex: "#F06595")))
        var stamens = Path()
        var tips = Path()
        let reach = size * 0.2
        let dot = max(0.7, size * 0.028)
        for i in 0..<9 {
            let a = Double(i) / 9 * 2 * .pi
            let end = CGPoint(x: cos(a) * reach, y: sin(a) * reach)
            stamens.move(to: .zero)
            stamens.addLine(to: end)
            tips.addEllipse(in: CGRect(x: end.x - dot, y: end.y - dot, width: dot * 2, height: dot * 2))
        }
        ctx.stroke(stamens, with: .color(Color(hex: "#E64980")), lineWidth: max(0.5, size * 0.02))
        ctx.fill(tips, with: .color(Color(hex: "#FCC419")))
    }

    private static let ice = Color(hex: "#74C0FC")

    private func drawFlake(in ctx: GraphicsContext, size: CGFloat) {
        let arm = size / 2
        var flake = Path()
        let branches: [(CGFloat, CGFloat)] = [(0.35, 0.32), (0.6, 0.22), (0.84, 0.1)]
        let side = sin(Double.pi / 3)
        let up = cos(Double.pi / 3)
        for k in 0..<6 {
            let t = CGAffineTransform(rotationAngle: CGFloat(k) * .pi / 3)
            var a = Path()
            a.move(to: .zero)
            a.addLine(to: CGPoint(x: 0, y: -arm))
            for (d, l) in branches {
                let start = CGPoint(x: 0, y: -d * arm)
                for s in [-1.0, 1.0] {
                    a.move(to: start)
                    a.addLine(to: CGPoint(x: s * side * l * arm, y: start.y - up * l * arm))
                }
            }
            flake.addPath(a.applying(t))
        }
        let width = max(1, size * 0.06)
        ctx.stroke(flake, with: .color(Self.ice.opacity(0.18)), style: StrokeStyle(lineWidth: width * 2.2, lineCap: .round, lineJoin: .round))
        ctx.stroke(flake, with: .color(Self.ice), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func drawSnow(in ctx: GraphicsContext, size: CGFloat) {
        let radius = size
        ctx.fill(
            Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(
                Gradient(colors: [Color(hex: "#A5D8FF"), Color(hex: "#A5D8FF").opacity(0)]),
                center: .zero, startRadius: 0, endRadius: radius
            )
        )
    }

    private func drawSeed(in ctx: GraphicsContext, size: CGFloat) {
        let u = size / 2
        let fluff = Color(hex: "#C8B48A")
        let hub = CGPoint(x: 0, y: -0.2 * u)

        var beak = Path()
        beak.move(to: CGPoint(x: 0, y: 0.6 * u))
        beak.addLine(to: hub)
        ctx.stroke(beak, with: .color(fluff), lineWidth: max(0.6, size * 0.025))

        var filaments = Path()
        var ends = Path()
        let dot = max(0.5, size * 0.018)
        for i in 0..<15 {
            let theta = (-75 + Double(i) * 150 / 14) * .pi / 180
            let len = 0.72 * u
            let end = CGPoint(x: sin(theta) * len, y: hub.y - cos(theta) * len)
            let control = CGPoint(x: sin(theta) * len * 0.45, y: hub.y - cos(theta) * len * 0.62)
            filaments.move(to: hub)
            filaments.addQuadCurve(to: end, control: control)
            ends.addEllipse(in: CGRect(x: end.x - dot, y: end.y - dot, width: dot * 2, height: dot * 2))
        }
        ctx.stroke(filaments, with: .color(fluff.opacity(0.85)), lineWidth: max(0.5, size * 0.018))
        ctx.fill(ends, with: .color(fluff))

        let seedW = 0.09 * u
        ctx.fill(Path(ellipseIn: CGRect(x: -seedW, y: 0.56 * u, width: seedW * 2, height: 0.34 * u)),
                 with: .color(Color(hex: "#8D6E4A")))
    }

    private func drawGlow(in ctx: GraphicsContext, size: CGFloat) {
        let radius = size / 2
        ctx.fill(
            Path(ellipseIn: CGRect(x: -radius, y: -radius, width: size, height: size)),
            with: .radialGradient(
                Gradient(colors: [Color(hex: "#FFE066"), Color(hex: "#FFD43B").opacity(0.5), Color(hex: "#FFD43B").opacity(0)]),
                center: .zero, startRadius: 0, endRadius: radius
            )
        )
    }
}

#Preview("Spring") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(seasonOverride: .spring)
    }
    .ignoresSafeArea()
}

#Preview("Summer") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(seasonOverride: .summer)
    }
    .ignoresSafeArea()
}

#Preview("Fall") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(seasonOverride: .fall)
    }
    .ignoresSafeArea()
}

#Preview("Winter") {
    ZStack {
        Color.appBackground
        SeasonalOverlayView(seasonOverride: .winter)
    }
    .ignoresSafeArea()
}
