import SwiftUI

struct StickerBulb: View {
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
        let glass = StickerTone.gold
        let base = StickerTone.purple
        ZStack(alignment: .topLeading) {
            ZStack {
                StickerShape(glyph: .bulb).sticker(glass, unit: unit, depth: depth)
                StickerShape(glyph: .bulbShine).shine(glass.highlight, width: 5, unit: unit)
                StickerShape(glyph: .bulbFilament).shine(glass.side, width: 3, unit: unit)
                StickerShape(glyph: .bulbBaseTop).sticker(base, unit: unit, depth: 0.8 * depth)
                StickerShape(glyph: .bulbBaseBottom).sticker(base, unit: unit, depth: 0.7 * depth)
            }
            .frame(width: size, height: size)

            if showsAccents {
                StickerStar(tone: .pink, size: 32 * unit)
                    .offset(x: 88 * unit, y: 6 * unit)
                StickerStar(tone: .blue, size: 24 * unit)
                    .offset(x: 6 * unit, y: 20 * unit)
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }
}

#Preview {
    StickerBulb(size: 168)
        .padding()
}
