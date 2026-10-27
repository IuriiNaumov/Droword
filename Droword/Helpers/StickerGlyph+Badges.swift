import SwiftUI

nonisolated extension StickerCanvas {
    func leaf(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, width: CGFloat) -> Path {
        let dx = x1 - x0
        let dy = y1 - y0
        let length = max(0.001, (dx * dx + dy * dy).squareRoot())
        let nx = -dy / length * width
        let ny = dx / length * width
        let mx = (x0 + x1) / 2
        let my = (y0 + y1) / 2
        var p = Path()
        p.move(to: pt(x0, y0))
        p.addQuadCurve(to: pt(x1, y1), control: pt(mx + nx, my + ny))
        p.addQuadCurve(to: pt(x0, y0), control: pt(mx - nx, my - ny))
        p.closeSubpath()
        return p
    }

    func merged(_ paths: [Path]) -> Path {
        guard var result = paths.first?.cgPath else { return Path() }
        for path in paths.dropFirst() {
            result = result.union(path.cgPath)
        }
        return Path(result)
    }
}

nonisolated extension StickerGlyph {
    static let potBody = StickerGlyph { c in
        c.polygon([(36, 84), (84, 84), (77, 110), (43, 110)], radius: 5)
    }
    static let potRim = StickerGlyph { c in c.roundedBox(30, 76, 60, 14, 6) }

    static let sproutStem = StickerGlyph { c in c.line([(60, 78), (60, 54)]) }
    static let sproutLeaves = StickerGlyph { c in
        var p = c.leaf(60, 58, 24, 38, width: 14)
        p.addPath(c.leaf(60, 54, 98, 28, width: 16))
        return p
    }

    static let herbStem = StickerGlyph { c in c.line([(60, 78), (60, 18)]) }
    static let herbLeaves = StickerGlyph { c in
        var p = c.leaf(60, 68, 28, 56, width: 9)
        p.addPath(c.leaf(60, 60, 94, 46, width: 9))
        p.addPath(c.leaf(60, 46, 30, 30, width: 9))
        p.addPath(c.leaf(60, 38, 90, 20, width: 9))
        p.addPath(c.leaf(60, 24, 62, 4, width: 7))
        return p
    }

    static let treeTrunk = StickerGlyph { c in
        c.polygon([(52, 62), (68, 62), (72, 108), (48, 108)], radius: 4)
    }
    static let treeCrown = StickerGlyph { c in
        c.merged([
            c.circle(60, 38, 28),
            c.circle(34, 58, 22),
            c.circle(86, 58, 22),
            c.roundedBox(30, 52, 60, 26, 13)
        ])
    }
    static let treeShine = StickerGlyph { c in c.arc(60, 38, 19, from: 200, to: 250) }

    static let trophyCup = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(30, 16))
        p.addLine(to: c.pt(90, 16))
        p.addCurve(to: c.pt(60, 74), control1: c.pt(90, 50), control2: c.pt(80, 74))
        p.addCurve(to: c.pt(30, 16), control1: c.pt(40, 74), control2: c.pt(30, 50))
        p.closeSubpath()
        return p
    }
    static let trophyHandles = StickerGlyph { c in
        var p = c.arc(31, 34, 14, from: 270, to: 90)
        p.addPath(c.arc(89, 34, 14, from: 270, to: 450))
        return p
    }
    static let trophyStem = StickerGlyph { c in c.roundedBox(53, 70, 14, 18, 3) }
    static let trophyBase = StickerGlyph { c in c.roundedBox(34, 86, 52, 20, 7) }
    static let trophyShine = StickerGlyph { c in c.line([(42, 26), (44, 46)]) }
    static let trophyStar = StickerGlyph { c in c.star(60, 38, 11) }

    static let crown = StickerGlyph { c in
        c.polygon([(18, 40), (40, 64), (60, 24), (80, 64), (102, 40), (92, 98), (28, 98)], radius: 5)
    }
    static let crownBand = StickerGlyph { c in c.roundedBox(28, 82, 64, 16, 4) }
    static let crownJewels = StickerGlyph { c in
        var p = c.circle(18, 38, 7)
        p.addPath(c.circle(60, 22, 8))
        p.addPath(c.circle(102, 38, 7))
        return p
    }
    static let crownGem = StickerGlyph { c in c.circle(60, 90, 5) }
    static let crownShine = StickerGlyph { c in c.line([(34, 60), (38, 78)]) }

    static let diamond = StickerGlyph { c in
        c.polygon([(32, 22), (88, 22), (110, 48), (60, 106), (10, 48)], radius: 4)
    }
    static let diamondTop = StickerGlyph { c in
        c.polygon([(32, 22), (88, 22), (110, 48), (10, 48)], radius: 4)
    }
    static let diamondFacets = StickerGlyph { c in
        var p = c.line([(32, 22), (44, 48), (60, 22), (76, 48), (88, 22)])
        p.addPath(c.line([(44, 48), (60, 104), (76, 48)]))
        return p
    }

    static let targetOuter = StickerGlyph { c in c.circle(56, 64, 44) }
    static let targetRing = StickerGlyph { c in c.circle(56, 64, 32) }
    static let targetMiddle = StickerGlyph { c in c.circle(56, 64, 21) }
    static let targetCenter = StickerGlyph { c in c.circle(56, 64, 9) }
    static let dartShaft = StickerGlyph { c in c.line([(58, 62), (98, 22)]) }
    static let dartFletch = StickerGlyph { c in
        c.polygon([(92, 14), (106, 14), (106, 28), (100, 34), (86, 20)], radius: 3)
    }

    static let notepad = StickerGlyph { c in c.roundedBox(18, 14, 66, 90, 10) }
    static let notepadLines = StickerGlyph { c in
        var p = c.line([(32, 36), (68, 36)])
        p.addPath(c.line([(32, 54), (68, 54)]))
        p.addPath(c.line([(32, 72), (52, 72)]))
        return p
    }
    static let pencilBody = StickerGlyph { c in c.line([(62, 96), (100, 58)]) }
    static let pencilEraser = StickerGlyph { c in c.line([(98, 60), (106, 52)]) }
    static let pencilTip = StickerGlyph { c in
        c.polygon([(50, 108), (55, 90), (68, 103)], radius: 2)
    }
}
