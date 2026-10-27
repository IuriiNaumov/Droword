import SwiftUI

struct StickerBook: View {
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
        let cover = StickerTone.blue
        ZStack(alignment: .topLeading) {
            ZStack {
                StickerShape(glyph: .bookCover).sticker(cover, unit: unit, depth: depth)
                StickerShape(glyph: .bookSpine).shine(cover.side, width: 3, unit: unit)
                StickerShape(glyph: .bookShine).shine(cover.highlight, width: 4, unit: unit)
                StickerShape(glyph: .bookLabel).fill(cover.highlight)
                StickerShape(glyph: .bookLabelLine).fill(cover.highlight.opacity(0.7))
                StickerShape(glyph: .bookPages).fill(StickerTone.paper.face)
                StickerShape(glyph: .bookPages).stroke(cover.line, lineWidth: 1.5 * unit * depth)
                StickerShape(glyph: .bookRibbon).sticker(.pink, unit: unit, depth: 0.6 * depth)
            }
            .frame(width: size, height: size)

            if showsAccents {
                StickerStar(tone: .gold, size: 34 * unit)
                    .offset(x: 90 * unit, y: 50 * unit)
                StickerStar(tone: .pink, size: 24 * unit)
                    .offset(x: 4 * unit, y: 8 * unit)
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }
}

#Preview {
    StickerBook(size: 168)
        .padding()
}
