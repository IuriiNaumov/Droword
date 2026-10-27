import SwiftUI

struct StickerIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    let art: StickerArt
    var size: CGFloat = 72

    private var unit: CGFloat { size / 120 }
    private var depth: CGFloat { max(1, 44 / size) }

    var body: some View {
        StickerPixelFrame(size: size) {
            content.frame(width: size, height: size)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch art {
        case .star: StickerStar(tone: .purple, size: size * 0.92, depth: depth)
        case .sparkles: StickerSparkles(size: size)
        case .wand: wand
        case .plus: plus
        case .bolt: bolt
        case .bulb: StickerBulb(size: size, showsAccents: false, depth: depth)
        case .brain: brain
        case .flame: flame
        case .book: StickerBook(size: size, showsAccents: false, depth: depth)
        case .calendar: calendar
        case .flag: flag
        case .medal: medal
        case .trash: trash
        case .offline: offline
        case .duplicate: duplicate
        case .check: StickerCheck(size: size, depth: depth)
        case .warning: warning
        case .swap: swap
        case .letters: letters
        case .camera: camera
        case .speaker: speaker
        case .chat: chat
        case .stack: stack
        case .dumbbell: dumbbell
        case .chart: chart
        case .question: StickerQuestion(size: size, showsAccents: false, depth: depth)
        case .tag: StickerTag(size: size, showsAccents: false, depth: depth)
        case .correct: markBadge(.badgeCheck, .green)
        case .wrong: markBadge(.badgeCross, .red)
        case .scan: scan
        case .addWord: addWord
        case .cards: cards
        case .palette: palette
        case .appIcon: appIcon
        case .sprout: plant(stem: .sproutStem, leaves: .sproutLeaves)
        case .herb: plant(stem: .herbStem, leaves: .herbLeaves)
        case .tree: tree
        case .trophy: trophy
        case .crown: crown
        case .diamond: diamond
        case .target: target
        case .notepad: notepad
        }
    }

    private var pot: some View {
        ZStack {
            solid(.potBody, .pink)
            solid(.potRim, .pink, depth: 0.6)
        }
    }

    private func plant(stem: StickerGlyph, leaves: StickerGlyph) -> some View {
        ZStack {
            tube(stem, .green, width: 6)
            solid(leaves, .green)
            pot
        }
    }

    private var tree: some View {
        ZStack {
            solid(.treeTrunk, .wood)
            solid(.treeCrown, .green)
            shine(.treeShine, StickerTone.green.highlight, width: 5)
        }
    }

    private var trophy: some View {
        ZStack {
            tube(.trophyHandles, .gold, width: 7)
            solid(.trophyStem, .gold, depth: 0.6)
            solid(.trophyBase, .purple)
            solid(.trophyCup, .gold)
            shine(.trophyShine, StickerTone.gold.highlight)
            StickerShape(glyph: .trophyStar).fill(StickerTone.gold.highlight)
        }
    }

    private var crown: some View {
        ZStack {
            solid(.crownJewels, .pink, depth: 0.6)
            solid(.crown, .gold)
            StickerShape(glyph: .crownBand).fill(StickerTone.gold.side)
            StickerShape(glyph: .crownGem).fill(StickerTone.blue.face)
            shine(.crownShine, StickerTone.gold.highlight)
        }
    }

    private var diamond: some View {
        ZStack {
            solid(.diamond, .blue)
            StickerShape(glyph: .diamondTop).fill(StickerTone.blue.highlight)
            StickerShape(glyph: .diamond).stroke(StickerTone.blue.line, style: StrokeStyle(lineWidth: 1.5 * unit * depth, lineJoin: .round))
            shine(.diamondFacets, StickerTone.blue.line, width: 2.5)
        }
    }

    private var target: some View {
        ZStack {
            solid(.targetOuter, .red)
            StickerShape(glyph: .targetRing).fill(StickerTone.paper.face)
            StickerShape(glyph: .targetMiddle).fill(StickerTone.red.face)
            StickerShape(glyph: .targetCenter).fill(StickerTone.paper.face)
            tube(.dartShaft, .purple, width: 6)
            solid(.dartFletch, .gold, depth: 0.6)
        }
    }

    private var notepad: some View {
        ZStack {
            solid(.notepad, .paper)
            shine(.notepadLines, StickerTone.blue.highlight, width: 5)
            tube(.pencilBody, .gold, width: 11)
            tube(.pencilEraser, .pink, width: 11)
            solid(.pencilTip, .wood, depth: 0.5)
        }
    }

    private func markBadge(_ mark: StickerGlyph, _ tone: StickerTone) -> some View {
        ZStack {
            solid(.badge, tone)
            shine(.badgeShine, tone.highlight, width: 5)
            shine(mark, StickerTone.paper.face, width: 12)
        }
    }

    private var scan: some View {
        ZStack {
            tube(.scanCorners, .purple, width: 9)
            solid(.scanDoc, .paper)
            shine(.scanDocLines, StickerTone.blue.highlight, width: 5)
            tube(.scanBeam, .pink, width: 5)
        }
    }

    private var addWord: some View {
        ZStack {
            solid(.wordCard, colorScheme == .dark ? .slate : .paper)
            shine(.wordCardTitle, StickerTone.blue.face, width: 8)
            shine(.wordCardLines, StickerTone.blue.highlight, width: 5)
        }
    }

    private var cards: some View {
        let paper = colorScheme == .dark ? StickerTone.slate : StickerTone.paper
        return ZStack {
            solid(.cardsBack, .pink, depth: 0.6)
            solid(.cardsMiddle, .gold, depth: 0.6)
            solid(.cardsFront, paper)
            shine(.cardsTitle, StickerTone.blue.face, width: 8)
            shine(.cardsLines, StickerTone.blue.highlight, width: 5)
        }
    }

    private var palette: some View {
        ZStack {
            ZStack {
                solid(.palette, .gold)
                StickerShape(glyph: .paletteHole).fill(Color.black).blendMode(.destinationOut)
                StickerShape(glyph: .paletteHole).stroke(StickerTone.gold.line, lineWidth: 1.5 * unit * depth)
            }
            .compositingGroup()
            StickerShape(glyph: .paletteDotPink).fill(StickerTone.pink.face)
            StickerShape(glyph: .paletteDotGold).fill(StickerTone.purple.face)
            StickerShape(glyph: .paletteDotGreen).fill(StickerTone.green.face)
            StickerShape(glyph: .paletteDotBlue).fill(StickerTone.blue.face)
        }
    }

    private var appIcon: some View {
        ZStack {
            solid(.appSquircle, .purple)
            shine(.appShine, StickerTone.purple.highlight, width: 5)
            accent(.gold, 52, x: 62, y: 60)
        }
    }

    private func solid(_ glyph: StickerGlyph, _ tone: StickerTone, depth scale: CGFloat = 1) -> some View {
        StickerShape(glyph: glyph).sticker(tone, unit: unit, depth: depth * scale)
    }

    private func tube(_ glyph: StickerGlyph, _ tone: StickerTone, width: CGFloat) -> some View {
        StickerShape(glyph: glyph).stickerStroke(tone, width: width, unit: unit, depth: depth)
    }

    private func shine(_ glyph: StickerGlyph, _ color: some ShapeStyle, width: CGFloat = 4.5) -> some View {
        StickerShape(glyph: glyph).shine(color, width: width, unit: unit)
    }

    private func accent(_ tone: StickerTone, _ starSize: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        StickerStar(tone: tone, size: starSize * unit, depth: max(1.8, depth))
            .offset(x: (x - 60) * unit, y: (y - 60) * unit)
    }

    private var wand: some View {
        ZStack {
            tube(.wandStick, .purple, width: 12)
            shine(.wandShine, StickerTone.purple.highlight, width: 3.5)
            accent(.gold, 58, x: 78, y: 42)
            accent(.pink, 24, x: 26, y: 30)
            accent(.blue, 20, x: 100, y: 88)
        }
    }

    private var plus: some View {
        ZStack {
            solid(.badge, .purple)
            shine(.badgeShine, StickerTone.purple.highlight, width: 5)
            shine(.plusMark, StickerTone.paper.face, width: 13)
        }
    }

    private var bolt: some View {
        ZStack {
            solid(.bolt, .gold)
            shine(.boltShine, StickerTone.gold.highlight)
        }
    }

    private var brain: some View {
        ZStack {
            solid(.brain, .pink)
            shine(.brainFolds, StickerTone.pink.side, width: 3.5)
            shine(.brainShine, StickerTone.pink.highlight)
        }
    }

    private var flame: some View {
        ZStack {
            solid(.flame, .red)
            solid(.flameCore, .gold, depth: 0.5)
            shine(.flameShine, StickerTone.red.highlight)
        }
    }

    private var calendar: some View {
        ZStack {
            solid(.calendarBody, .paper)
            StickerShape(glyph: .calendarTop).fill(StickerTone.pink.face)
            StickerShape(glyph: .calendarBody).stroke(StickerTone.blue.line, lineWidth: 1.5 * unit * depth)
            StickerShape(glyph: .calendarDots).fill(StickerTone.blue.face)
            solid(.calendarRings, .purple, depth: 0.6)
        }
    }

    private var flag: some View {
        ZStack {
            tube(.flagPole, .purple, width: 6)
            solid(.flagCloth, .green)
            shine(.flagShine, StickerTone.green.highlight)
            solid(.flagKnob, .gold, depth: 0.6)
        }
    }

    private var medal: some View {
        ZStack {
            solid(.medalStrapLeft, .blue, depth: 0.7)
            solid(.medalStrapRight, .pink, depth: 0.7)
            solid(.medalDisc, .gold)
            shine(.medalRing, StickerTone.gold.side, width: 2.5)
            StickerShape(glyph: .medalStar).fill(StickerTone.gold.highlight)
            shine(.medalShine, StickerTone.gold.highlight)
        }
    }

    private var trash: some View {
        ZStack {
            shine(.trashHandle, StickerTone.red.side, width: 6)
            solid(.trashCan, .red)
            shine(.trashStripes, StickerTone.red.side, width: 4.5)
            solid(.trashLid, .red, depth: 0.7)
            shine(.trashShine, StickerTone.red.highlight, width: 3.5)
        }
    }

    private var offline: some View {
        ZStack {
            tube(.wifiArcs, .gold, width: 11)
            solid(.wifiDot, .gold)
            tube(.slash, .red, width: 9)
        }
    }

    private var duplicate: some View {
        ZStack {
            solid(.docBack, .blue)
            solid(.docFront, .paper)
            shine(.docLines, StickerTone.blue.highlight, width: 5)
        }
    }

    private var warning: some View {
        ZStack {
            solid(.warningTriangle, .gold)
            shine(.warningBar, StickerTone.gold.line, width: 10)
            StickerShape(glyph: .warningDot).fill(StickerTone.gold.line)
        }
    }

    private var swap: some View {
        ZStack {
            tube(.arrowRight, .blue, width: 11)
            tube(.arrowLeft, .pink, width: 11)
        }
    }

    private var letters: some View {
        ZStack {
            tube(.letterA, .purple, width: 15)
            shine(.letterAShine, StickerTone.purple.highlight)
            accent(.gold, 30, x: 98, y: 22)
        }
    }

    private var camera: some View {
        ZStack {
            solid(.cameraTop, .blue, depth: 0.6)
            solid(.cameraBody, .blue)
            shine(.cameraShine, StickerTone.blue.highlight)
            solid(.cameraLens, .paper, depth: 0.5)
            StickerShape(glyph: .cameraLensCore).fill(StickerTone.purple.face)
            StickerShape(glyph: .cameraLensShine).fill(StickerTone.purple.highlight)
            StickerShape(glyph: .cameraFlash).fill(StickerTone.gold.face)
        }
    }

    private var speaker: some View {
        ZStack {
            solid(.speakerBody, .purple)
            shine(.speakerShine, StickerTone.purple.highlight)
            tube(.speakerWaves, .blue, width: 9)
        }
    }

    private var chat: some View {
        ZStack {
            solid(.bubbleBack, .pink)
            solid(.bubbleFront, .blue)
            shine(.bubbleShine, StickerTone.blue.highlight)
            StickerShape(glyph: .bubbleDots).fill(StickerTone.paper.face)
        }
    }

    private var stack: some View {
        ZStack {
            solid(.stackBack, .pink, depth: 0.6)
            solid(.stackMiddle, .gold, depth: 0.6)
            solid(.stackFront, .purple)
            shine(.stackShine, StickerTone.purple.highlight)
        }
    }

    private var dumbbell: some View {
        ZStack {
            tube(.dumbbellBar, .purple, width: 8)
            solid(.dumbbellOuter, .blue, depth: 0.7)
            solid(.dumbbellInner, .blue)
            shine(.dumbbellShine, StickerTone.blue.highlight, width: 3.5)
        }
    }

    private var chart: some View {
        ZStack {
            shine(.chartAxes, StickerTone.purple.face, width: 6)
            tube(.chartLine, .green, width: 10)
            accent(.gold, 30, x: 96, y: 32)
        }
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(84)), count: 4), spacing: 16) {
        ForEach(StickerArt.allCases) { art in
            StickerIcon(art: art, size: 72)
        }
    }
    .padding()
}
