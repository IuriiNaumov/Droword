import SwiftUI

struct StickerHeart: View {
    var tone: StickerTone = .red
    var size: CGFloat = 40
    var depth: CGFloat = 1.8

    var body: some View {
        StickerPixelFrame(size: size) { art }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var art: some View {
        let unit = size / 120
        ZStack {
            StickerShape(glyph: .heart).sticker(tone, unit: unit, depth: depth)
            StickerShape(glyph: .heartShine).shine(tone.highlight, width: 6, unit: unit)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        StickerHeart(size: 80, depth: 1)
        StickerHeart(size: 40)
        StickerHeart(size: 22)
        StickerHeart(tone: .ash, size: 22)
    }
    .padding()
}
