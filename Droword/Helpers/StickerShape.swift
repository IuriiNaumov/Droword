import SwiftUI

nonisolated struct StickerCanvas {
    let unit: CGFloat
    let originX: CGFloat
    let originY: CGFloat

    init(rect: CGRect) {
        unit = min(rect.width, rect.height) / 120
        originX = rect.midX - 60 * unit
        originY = rect.midY - 60 * unit
    }

    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: originX + x * unit, y: originY + y * unit)
    }

    func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: originX + x * unit, y: originY + y * unit, width: w * unit, height: h * unit)
    }

    func roundedBox(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: box(x, y, w, h), cornerRadius: r * unit, style: .continuous)
    }

    func topRoundedBox(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(
            roundedRect: box(x, y, w, h),
            cornerRadii: RectangleCornerRadii(topLeading: r * unit, bottomLeading: 0, bottomTrailing: 0, topTrailing: r * unit),
            style: .continuous
        )
    }

    func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: box(cx - r, cy - r, r * 2, r * 2))
    }

    func line(_ points: [(CGFloat, CGFloat)]) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: pt(first.0, first.1))
        for point in points.dropFirst() {
            p.addLine(to: pt(point.0, point.1))
        }
        return p
    }

    func polygon(_ points: [(CGFloat, CGFloat)], radius: CGFloat) -> Path {
        var p = Path()
        let corners = points.map { pt($0.0, $0.1) }
        guard let first = corners.first, let last = corners.last else { return p }
        p.move(to: CGPoint(x: (first.x + last.x) / 2, y: (first.y + last.y) / 2))
        for index in corners.indices {
            p.addArc(tangent1End: corners[index], tangent2End: corners[(index + 1) % corners.count], radius: radius * unit)
        }
        p.closeSubpath()
        return p
    }

    func arc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, from start: CGFloat, to end: CGFloat) -> Path {
        var p = Path()
        let steps = 24
        for step in 0...steps {
            let degrees = start + (end - start) * CGFloat(step) / CGFloat(steps)
            let radians = degrees * .pi / 180
            let point = pt(cx + r * cos(radians), cy + r * sin(radians))
            if step == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        return p
    }

    func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        let near = r * 0.087
        let far = r * 0.348
        var p = Path()
        p.move(to: pt(cx, cy - r))
        p.addCurve(to: pt(cx + r, cy), control1: pt(cx + near, cy - far), control2: pt(cx + far, cy - near))
        p.addCurve(to: pt(cx, cy + r), control1: pt(cx + far, cy + near), control2: pt(cx + near, cy + far))
        p.addCurve(to: pt(cx - r, cy), control1: pt(cx - near, cy + far), control2: pt(cx - far, cy + near))
        p.addCurve(to: pt(cx, cy - r), control1: pt(cx - far, cy - near), control2: pt(cx - near, cy - far))
        p.closeSubpath()
        return p
    }
}

nonisolated struct StickerGlyph: Sendable {
    let build: @Sendable (StickerCanvas) -> Path
}

struct StickerShape: Shape {
    let glyph: StickerGlyph

    nonisolated func path(in rect: CGRect) -> Path {
        glyph.build(StickerCanvas(rect: rect))
    }
}

nonisolated extension StickerGlyph {
    static let star = StickerGlyph { c in c.star(60, 60, 46) }

    static let starShine = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(60, 24))
        p.addCurve(to: c.pt(74, 54), control1: c.pt(62, 42), control2: c.pt(66, 50))
        return p
    }

    static let heart = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(60, 102))
        p.addCurve(to: c.pt(12, 48), control1: c.pt(36, 86), control2: c.pt(12, 70))
        p.addCurve(to: c.pt(36, 22), control1: c.pt(12, 32), control2: c.pt(22, 22))
        p.addCurve(to: c.pt(60, 38), control1: c.pt(48, 22), control2: c.pt(56, 30))
        p.addCurve(to: c.pt(84, 22), control1: c.pt(64, 30), control2: c.pt(72, 22))
        p.addCurve(to: c.pt(108, 48), control1: c.pt(98, 22), control2: c.pt(108, 32))
        p.addCurve(to: c.pt(60, 102), control1: c.pt(108, 70), control2: c.pt(84, 86))
        p.closeSubpath()
        return p
    }

    static let heartShine = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(26, 46))
        p.addCurve(to: c.pt(38, 33), control1: c.pt(27, 39), control2: c.pt(32, 34))
        return p
    }

    static let question = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(40, 44))
        p.addCurve(to: c.pt(63, 18), control1: c.pt(40, 27), control2: c.pt(51, 18))
        p.addCurve(to: c.pt(86, 41), control1: c.pt(77, 18), control2: c.pt(86, 28))
        p.addCurve(to: c.pt(63, 72), control1: c.pt(86, 55), control2: c.pt(66, 59))
        return p
    }

    static let questionShine = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(45, 40))
        p.addCurve(to: c.pt(61, 25), control1: c.pt(46, 30), control2: c.pt(53, 25))
        return p
    }

    static let questionDot = StickerGlyph { c in c.circle(63, 93, 10.5) }
    static let questionDotShine = StickerGlyph { c in c.circle(59.5, 89.5, 3) }

    static let bulb = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(60, 14))
        p.addCurve(to: c.pt(26, 48), control1: c.pt(39, 14), control2: c.pt(26, 30))
        p.addCurve(to: c.pt(40, 76), control1: c.pt(26, 61), control2: c.pt(33, 69))
        p.addCurve(to: c.pt(45, 87), control1: c.pt(44, 80), control2: c.pt(45, 83))
        p.addLine(to: c.pt(75, 87))
        p.addCurve(to: c.pt(80, 76), control1: c.pt(75, 83), control2: c.pt(76, 80))
        p.addCurve(to: c.pt(94, 48), control1: c.pt(87, 69), control2: c.pt(94, 61))
        p.addCurve(to: c.pt(60, 14), control1: c.pt(94, 30), control2: c.pt(81, 14))
        p.closeSubpath()
        return p
    }

    static let bulbShine = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(40, 46))
        p.addCurve(to: c.pt(58, 25), control1: c.pt(40, 34), control2: c.pt(48, 26))
        return p
    }

    static let bulbFilament = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(52, 87))
        p.addLine(to: c.pt(52, 70))
        p.addCurve(to: c.pt(68, 70), control1: c.pt(52, 64), control2: c.pt(68, 64))
        p.addLine(to: c.pt(68, 87))
        return p
    }

    static let bulbBaseTop = StickerGlyph { c in c.roundedBox(44, 89, 32, 10, 5) }
    static let bulbBaseBottom = StickerGlyph { c in c.roundedBox(48, 101, 24, 9, 4.5) }

    static let tag = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(30, 40))
        p.addCurve(to: c.pt(38, 32), control1: c.pt(30, 35), control2: c.pt(34, 32))
        p.addLine(to: c.pt(70, 32))
        p.addCurve(to: c.pt(77, 35), control1: c.pt(73, 32), control2: c.pt(75, 33))
        p.addLine(to: c.pt(97, 57))
        p.addCurve(to: c.pt(97, 69), control1: c.pt(100, 60), control2: c.pt(100, 66))
        p.addLine(to: c.pt(77, 91))
        p.addCurve(to: c.pt(70, 94), control1: c.pt(75, 93), control2: c.pt(73, 94))
        p.addLine(to: c.pt(38, 94))
        p.addCurve(to: c.pt(30, 86), control1: c.pt(34, 94), control2: c.pt(30, 91))
        p.closeSubpath()
        return p
    }

    static let tagShine = StickerGlyph { c in c.line([(38, 42), (66, 42)]) }
    static let tagHoleRim = StickerGlyph { c in c.circle(45, 63, 8) }
    static let tagHole = StickerGlyph { c in c.circle(46, 64.5, 6.5) }

    static let bookCover = StickerGlyph { c in c.roundedBox(24, 14, 72, 88, 12) }
    static let bookSpine = StickerGlyph { c in c.line([(38, 20), (38, 84)]) }
    static let bookShine = StickerGlyph { c in c.line([(30, 26), (30, 60)]) }
    static let bookPages = StickerGlyph { c in c.roundedBox(34, 86, 58, 12, 5) }
    static let bookLabel = StickerGlyph { c in c.roundedBox(48, 34, 34, 12, 6) }
    static let bookLabelLine = StickerGlyph { c in c.roundedBox(52, 52, 26, 6, 3) }
    static let bookRibbon = StickerGlyph { c in c.polygon([(76, 14), (88, 14), (88, 46), (82, 40), (76, 46)], radius: 1) }

    static let check = StickerGlyph { c in c.line([(28, 62), (50, 84), (92, 38)]) }
    static let checkShine = StickerGlyph { c in c.line([(33, 60), (44, 71)]) }
}

#Preview {
    StickerShape(glyph: .star)
        .fill(StickerTone.purple.face)
        .frame(width: 120, height: 120)
}
