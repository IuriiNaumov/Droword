import SwiftUI

struct StickerTag: View {
    var size: CGFloat = 150
    var showsAccents: Bool = true
    var depth: CGFloat = 1

    var body: some View {
        StickerPixelFrame(size: size) { art }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var art: some View {
        let unit = size / 120
        let tone = StickerTone.pink
        ZStack(alignment: .topLeading) {
            ZStack {
                StickerShape(glyph: .tag).sticker(tone, unit: unit, depth: depth)
                StickerShape(glyph: .tagShine).shine(tone.highlight, width: 5, unit: unit)
                StickerShape(glyph: .tagHoleRim).fill(tone.side)
                StickerShape(glyph: .tagHole).fill(Color.black).blendMode(.destinationOut)
                StickerShape(glyph: .tagHole).stroke(tone.line, lineWidth: 1.5 * unit * depth)
            }
            .compositingGroup()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(-28), anchor: UnitPoint(x: 64.0 / 120, y: 63.0 / 120))

            if showsAccents {
                StickerStar(tone: .gold, size: 36 * unit)
                    .offset(x: 84 * unit, y: 6 * unit)
                StickerStar(tone: .purple, size: 24 * unit)
                    .offset(x: 14 * unit, y: 86 * unit)
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }
}

#Preview {
    StickerTag(size: 168)
        .padding()
}
