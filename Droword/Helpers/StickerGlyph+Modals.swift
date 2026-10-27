import SwiftUI

nonisolated extension StickerGlyph {
    static let badge = StickerGlyph { c in c.circle(60, 58, 42) }
    static let badgeShine = StickerGlyph { c in c.arc(60, 58, 32, from: 195, to: 245) }
    static let plusMark = StickerGlyph { c in
        var p = c.line([(60, 38), (60, 78)])
        p.addPath(c.line([(40, 58), (80, 58)]))
        return p
    }

    static let bolt = StickerGlyph { c in
        c.polygon([(78, 8), (20, 70), (52, 70), (40, 112), (102, 44), (68, 44)], radius: 5)
    }
    static let boltShine = StickerGlyph { c in c.line([(66, 24), (40, 54)]) }

    static let brain = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(60, 28))
        p.addCurve(to: c.pt(34, 32), control1: c.pt(54, 18), control2: c.pt(36, 18))
        p.addCurve(to: c.pt(24, 54), control1: c.pt(22, 32), control2: c.pt(16, 46))
        p.addCurve(to: c.pt(32, 80), control1: c.pt(16, 62), control2: c.pt(20, 78))
        p.addCurve(to: c.pt(60, 86), control1: c.pt(34, 92), control2: c.pt(52, 96))
        p.addCurve(to: c.pt(88, 80), control1: c.pt(68, 96), control2: c.pt(86, 92))
        p.addCurve(to: c.pt(96, 54), control1: c.pt(100, 78), control2: c.pt(104, 62))
        p.addCurve(to: c.pt(86, 32), control1: c.pt(104, 46), control2: c.pt(98, 32))
        p.addCurve(to: c.pt(60, 28), control1: c.pt(84, 18), control2: c.pt(66, 18))
        p.closeSubpath()
        return p
    }
    static let brainFolds = StickerGlyph { c in
        var p = c.line([(60, 32), (60, 82)])
        var fold = Path()
        fold.move(to: c.pt(36, 48))
        fold.addCurve(to: c.pt(48, 56), control1: c.pt(42, 44), control2: c.pt(48, 48))
        fold.move(to: c.pt(72, 48))
        fold.addCurve(to: c.pt(84, 54), control1: c.pt(76, 44), control2: c.pt(84, 46))
        fold.move(to: c.pt(34, 68))
        fold.addCurve(to: c.pt(46, 74), control1: c.pt(40, 64), control2: c.pt(46, 68))
        fold.move(to: c.pt(74, 66))
        fold.addCurve(to: c.pt(86, 70), control1: c.pt(78, 62), control2: c.pt(86, 64))
        p.addPath(fold)
        return p
    }
    static let brainShine = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(36, 34))
        p.addCurve(to: c.pt(52, 28), control1: c.pt(40, 28), control2: c.pt(46, 26))
        return p
    }

    static let flame = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(60, 108))
        p.addCurve(to: c.pt(24, 74), control1: c.pt(36, 108), control2: c.pt(24, 92))
        p.addCurve(to: c.pt(46, 22), control1: c.pt(24, 54), control2: c.pt(42, 44))
        p.addCurve(to: c.pt(60, 56), control1: c.pt(58, 32), control2: c.pt(62, 44))
        p.addCurve(to: c.pt(72, 32), control1: c.pt(68, 50), control2: c.pt(72, 42))
        p.addCurve(to: c.pt(96, 76), control1: c.pt(88, 46), control2: c.pt(96, 60))
        p.addCurve(to: c.pt(60, 108), control1: c.pt(96, 94), control2: c.pt(82, 108))
        p.closeSubpath()
        return p
    }
    static let flameCore = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(60, 102))
        p.addCurve(to: c.pt(42, 84), control1: c.pt(48, 102), control2: c.pt(42, 94))
        p.addCurve(to: c.pt(56, 60), control1: c.pt(42, 74), control2: c.pt(52, 68))
        p.addCurve(to: c.pt(76, 84), control1: c.pt(66, 68), control2: c.pt(76, 74))
        p.addCurve(to: c.pt(60, 102), control1: c.pt(76, 94), control2: c.pt(70, 102))
        p.closeSubpath()
        return p
    }
    static let flameShine = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(34, 74))
        p.addCurve(to: c.pt(42, 50), control1: c.pt(34, 64), control2: c.pt(38, 56))
        return p
    }

    static let wandStick = StickerGlyph { c in c.line([(26, 98), (70, 54)]) }
    static let wandShine = StickerGlyph { c in c.line([(30, 90), (46, 74)]) }

    static let calendarBody = StickerGlyph { c in c.roundedBox(18, 26, 84, 78, 16) }
    static let calendarTop = StickerGlyph { c in c.topRoundedBox(18, 26, 84, 26, 16) }
    static let calendarRings = StickerGlyph { c in
        var p = c.roundedBox(36, 16, 10, 22, 5)
        p.addPath(c.roundedBox(74, 16, 10, 22, 5))
        return p
    }
    static let calendarDots = StickerGlyph { c in
        var p = Path()
        for x in [32, 54, 76] as [CGFloat] {
            for y in [62, 82] as [CGFloat] {
                p.addPath(c.roundedBox(x, y, 12, 12, 3.5))
            }
        }
        return p
    }

    static let flagPole = StickerGlyph { c in c.line([(32, 24), (32, 104)]) }
    static let flagKnob = StickerGlyph { c in c.circle(32, 18, 7) }
    static let flagCloth = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(38, 26))
        p.addCurve(to: c.pt(70, 28), control1: c.pt(50, 18), control2: c.pt(60, 32))
        p.addCurve(to: c.pt(98, 24), control1: c.pt(80, 24), control2: c.pt(90, 20))
        p.addLine(to: c.pt(98, 68))
        p.addCurve(to: c.pt(70, 72), control1: c.pt(90, 64), control2: c.pt(80, 68))
        p.addCurve(to: c.pt(38, 70), control1: c.pt(60, 76), control2: c.pt(50, 64))
        p.closeSubpath()
        return p
    }
    static let flagShine = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(46, 32))
        p.addCurve(to: c.pt(64, 36), control1: c.pt(52, 28), control2: c.pt(58, 34))
        return p
    }

    static let medalStrapLeft = StickerGlyph { c in c.polygon([(32, 12), (54, 12), (68, 54), (46, 54)], radius: 3) }
    static let medalStrapRight = StickerGlyph { c in c.polygon([(88, 12), (66, 12), (52, 54), (74, 54)], radius: 3) }
    static let medalDisc = StickerGlyph { c in c.circle(60, 76, 30) }
    static let medalRing = StickerGlyph { c in c.circle(60, 76, 21) }
    static let medalStar = StickerGlyph { c in c.star(60, 76, 13) }
    static let medalShine = StickerGlyph { c in c.arc(60, 76, 25, from: 200, to: 245) }

    static let trashLid = StickerGlyph { c in c.roundedBox(20, 26, 80, 13, 6.5) }
    static let trashHandle = StickerGlyph { c in
        var p = Path()
        p.move(to: c.pt(46, 26))
        p.addLine(to: c.pt(46, 21))
        p.addCurve(to: c.pt(54, 14), control1: c.pt(46, 17), control2: c.pt(49, 14))
        p.addLine(to: c.pt(66, 14))
        p.addCurve(to: c.pt(74, 21), control1: c.pt(71, 14), control2: c.pt(74, 17))
        p.addLine(to: c.pt(74, 26))
        return p
    }
    static let trashCan = StickerGlyph { c in c.polygon([(28, 44), (92, 44), (85, 106), (35, 106)], radius: 9) }
    static let trashStripes = StickerGlyph { c in
        var p = c.line([(47, 58), (49, 92)])
        p.addPath(c.line([(60, 58), (60, 92)]))
        p.addPath(c.line([(73, 58), (71, 92)]))
        return p
    }
    static let trashShine = StickerGlyph { c in c.line([(30, 32), (48, 32)]) }

    static let wifiArcs = StickerGlyph { c in
        var p = c.arc(60, 96, 20, from: 232, to: 308)
        p.addPath(c.arc(60, 96, 39, from: 232, to: 308))
        p.addPath(c.arc(60, 96, 58, from: 232, to: 308))
        return p
    }
    static let wifiDot = StickerGlyph { c in c.circle(60, 96, 8) }
    static let slash = StickerGlyph { c in c.line([(26, 22), (96, 102)]) }

    static let docBack = StickerGlyph { c in c.roundedBox(40, 14, 60, 76, 13) }
    static let docFront = StickerGlyph { c in c.roundedBox(20, 32, 60, 78, 13) }
    static let docLines = StickerGlyph { c in
        var p = c.line([(32, 54), (66, 54)])
        p.addPath(c.line([(32, 70), (68, 70)]))
        p.addPath(c.line([(32, 86), (54, 86)]))
        return p
    }

    static let warningTriangle = StickerGlyph { c in c.polygon([(60, 14), (110, 102), (10, 102)], radius: 12) }
    static let warningBar = StickerGlyph { c in c.line([(60, 46), (60, 70)]) }
    static let warningDot = StickerGlyph { c in c.circle(60, 86, 6.5) }

    static let arrowRight = StickerGlyph { c in
        var p = c.line([(24, 40), (92, 40)])
        p.addPath(c.line([(76, 24), (94, 40), (76, 56)]))
        return p
    }
    static let arrowLeft = StickerGlyph { c in
        var p = c.line([(96, 82), (28, 82)])
        p.addPath(c.line([(44, 66), (26, 82), (44, 98)]))
        return p
    }

    static let letterA = StickerGlyph { c in
        var p = c.line([(28, 102), (60, 22), (92, 102)])
        p.addPath(c.line([(42, 74), (78, 74)]))
        return p
    }
    static let letterAShine = StickerGlyph { c in c.line([(52, 36), (44, 56)]) }

    static let cameraTop = StickerGlyph { c in c.roundedBox(38, 22, 38, 22, 7) }
    static let cameraBody = StickerGlyph { c in c.roundedBox(12, 36, 96, 66, 17) }
    static let cameraLens = StickerGlyph { c in c.circle(60, 69, 22) }
    static let cameraLensCore = StickerGlyph { c in c.circle(60, 69, 12) }
    static let cameraLensShine = StickerGlyph { c in c.circle(55, 64, 4) }
    static let cameraFlash = StickerGlyph { c in c.circle(90, 50, 5) }
    static let cameraShine = StickerGlyph { c in c.line([(22, 50), (22, 70)]) }

    static let speakerBody = StickerGlyph { c in
        c.polygon([(14, 44), (40, 44), (64, 22), (64, 98), (40, 76), (14, 76)], radius: 6)
    }
    static let speakerShine = StickerGlyph { c in c.line([(22, 52), (36, 52)]) }
    static let speakerWaves = StickerGlyph { c in
        var p = c.arc(66, 60, 18, from: -42, to: 42)
        p.addPath(c.arc(66, 60, 36, from: -42, to: 42))
        return p
    }

    static let bubbleBack = StickerGlyph { c in
        c.roundedBox(44, 14, 64, 46, 20).union(c.polygon([(80, 52), (102, 74), (66, 58)], radius: 3))
    }
    static let bubbleFront = StickerGlyph { c in
        c.roundedBox(12, 38, 72, 52, 22).union(c.polygon([(24, 80), (18, 106), (48, 86)], radius: 3))
    }
    static let bubbleDots = StickerGlyph { c in
        var p = c.circle(33, 64, 5.5)
        p.addPath(c.circle(48, 64, 5.5))
        p.addPath(c.circle(63, 64, 5.5))
        return p
    }
    static let bubbleShine = StickerGlyph { c in c.line([(26, 50), (40, 48)]) }

    static let stackBack = StickerGlyph { c in c.roundedBox(32, 18, 56, 22, 9) }
    static let stackMiddle = StickerGlyph { c in c.roundedBox(21, 30, 78, 24, 10) }
    static let stackFront = StickerGlyph { c in c.roundedBox(10, 44, 100, 58, 16) }
    static let stackShine = StickerGlyph { c in c.line([(22, 58), (22, 80)]) }

    static let dumbbellBar = StickerGlyph { c in c.line([(34, 60), (86, 60)]) }
    static let dumbbellOuter = StickerGlyph { c in
        var p = c.roundedBox(10, 42, 16, 36, 7)
        p.addPath(c.roundedBox(94, 42, 16, 36, 7))
        return p
    }
    static let dumbbellInner = StickerGlyph { c in
        var p = c.roundedBox(22, 28, 18, 64, 9)
        p.addPath(c.roundedBox(80, 28, 18, 64, 9))
        return p
    }
    static let dumbbellShine = StickerGlyph { c in
        var p = c.line([(28, 36), (28, 56)])
        p.addPath(c.line([(86, 36), (86, 56)]))
        return p
    }

    static let chartAxes = StickerGlyph { c in c.line([(20, 16), (20, 100), (106, 100)]) }
    static let chartLine = StickerGlyph { c in c.line([(32, 82), (52, 58), (68, 70), (92, 38)]) }
}
