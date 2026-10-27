import SwiftUI

nonisolated struct StickerTone: Sendable {
    enum Kind: Sendable {
        case purple
        case blue
        case gold
        case pink
        case green
        case red
        case wood
        case ash
        case paper
    }

    let kind: Kind

    var face: StickerPaint { StickerPaint(kind: kind, role: .face) }
    var side: StickerPaint { StickerPaint(kind: kind, role: .side) }
    var highlight: StickerPaint { StickerPaint(kind: kind, role: .highlight) }
    var line: StickerPaint { StickerPaint(kind: kind, role: .line) }

    static let purple = StickerTone(kind: .purple)
    static let blue = StickerTone(kind: .blue)
    static let gold = StickerTone(kind: .gold)
    static let pink = StickerTone(kind: .pink)
    static let green = StickerTone(kind: .green)
    static let red = StickerTone(kind: .red)
    static let wood = StickerTone(kind: .wood)
    static let ash = StickerTone(kind: .ash)
    static let paper = StickerTone(kind: .paper)
    static let flagLine = StickerColors.rgb(0x2E2A4F)
}

extension Shape {
    func sticker(_ tone: StickerTone, unit: CGFloat, depth: CGFloat = 1) -> some View {
        StickerSurface(shape: self, tone: tone, unit: unit, depth: depth)
    }

    func stickerStroke(_ tone: StickerTone, width: CGFloat, unit: CGFloat, depth: CGFloat = 1) -> some View {
        StickerStrokeSurface(shape: self, tone: tone, width: width, unit: unit, depth: depth)
    }

    func shine(_ color: some ShapeStyle, width: CGFloat, unit: CGFloat) -> some View {
        stroke(color, style: StrokeStyle(lineWidth: width * unit, lineCap: .round, lineJoin: .round))
    }
}
