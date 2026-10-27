import SwiftUI

nonisolated extension StickerGlyph {
    static let badgeCheck = StickerGlyph { c in c.line([(40, 58), (54, 72), (80, 44)]) }
    static let badgeCross = StickerGlyph { c in
        var p = c.line([(44, 42), (76, 74)])
        p.addPath(c.line([(76, 42), (44, 74)]))
        return p
    }

    static let scanCorners = StickerGlyph { c in
        var p = c.line([(16, 40), (16, 16), (40, 16)])
        p.addPath(c.line([(80, 16), (104, 16), (104, 40)]))
        p.addPath(c.line([(104, 80), (104, 104), (80, 104)]))
        p.addPath(c.line([(40, 104), (16, 104), (16, 80)]))
        return p
    }
    static let scanDoc = StickerGlyph { c in c.roundedBox(34, 28, 52, 64, 10) }
    static let scanDocLines = StickerGlyph { c in
        var p = c.line([(45, 46), (75, 46)])
        p.addPath(c.line([(45, 74), (65, 74)]))
        return p
    }
    static let scanBeam = StickerGlyph { c in c.line([(24, 60), (96, 60)]) }

    static let wordCard = StickerGlyph { c in c.roundedBox(12, 14, 80, 90, 15) }
    static let wordCardTitle = StickerGlyph { c in c.line([(28, 38), (66, 38)]) }
    static let wordCardLines = StickerGlyph { c in
        var p = c.line([(28, 58), (62, 58)])
        p.addPath(c.line([(28, 74), (50, 74)]))
        return p
    }
    static let cornerBadge = StickerGlyph { c in c.circle(86, 86, 24) }
    static let cornerPlus = StickerGlyph { c in
        var p = c.line([(86, 75), (86, 97)])
        p.addPath(c.line([(75, 86), (97, 86)]))
        return p
    }

    static let palette = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(60, 14))
        p.addCurve(to: c.pt(106, 58), control1: c.pt(86, 14), control2: c.pt(106, 32))
        p.addCurve(to: c.pt(80, 80), control1: c.pt(106, 72), control2: c.pt(94, 80))
        p.addCurve(to: c.pt(70, 96), control1: c.pt(70, 80), control2: c.pt(66, 88))
        p.addCurve(to: c.pt(56, 106), control1: c.pt(74, 104), control2: c.pt(66, 106))
        p.addCurve(to: c.pt(14, 60), control1: c.pt(32, 106), control2: c.pt(14, 86))
        p.addCurve(to: c.pt(60, 14), control1: c.pt(14, 34), control2: c.pt(34, 14))
        p.closeSubpath()
        return p
    }
    static let paletteHole = StickerGlyph { c in c.circle(40, 80, 8) }
    static let paletteDotPink = StickerGlyph { c in c.circle(36, 50, 8.5) }
    static let paletteDotGold = StickerGlyph { c in c.circle(56, 32, 8.5) }
    static let paletteDotGreen = StickerGlyph { c in c.circle(80, 38, 8.5) }
    static let paletteDotBlue = StickerGlyph { c in c.circle(88, 60, 7.5) }

    static let appSquircle = StickerGlyph { c in c.roundedBox(16, 16, 88, 88, 26) }
    static let appShine = StickerGlyph { c in c.line([(28, 34), (28, 54)]) }
}
