import SwiftUI

struct StickerQuestion: View {
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
        let tone = StickerTone.blue
        ZStack(alignment: .topLeading) {
            ZStack {
                StickerShape(glyph: .question).stickerStroke(tone, width: 16, unit: unit, depth: depth)
                StickerShape(glyph: .questionShine).shine(tone.highlight, width: 4.5, unit: unit)
                StickerShape(glyph: .questionDot).sticker(tone, unit: unit, depth: depth)
                StickerShape(glyph: .questionDotShine).fill(tone.highlight)
            }
            .frame(width: size, height: size)
            .offset(x: -2 * unit, y: 2 * unit)

            if showsAccents {
                StickerStar(tone: .gold, size: 34 * unit)
                    .offset(x: 86 * unit, y: 12 * unit)
                StickerStar(tone: .pink, size: 24 * unit)
                    .offset(x: 12 * unit, y: 70 * unit)
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }
}

#Preview {
    StickerQuestion(size: 168)
        .padding()
}
