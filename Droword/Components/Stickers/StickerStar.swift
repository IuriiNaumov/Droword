import SwiftUI

struct StickerStar: View {
    var tone: StickerTone = .purple
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
            StickerShape(glyph: .star).sticker(tone, unit: unit, depth: depth)
            StickerShape(glyph: .starShine).shine(tone.highlight, width: 5, unit: unit)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        StickerStar(tone: .purple, size: 80, depth: 1)
        StickerStar(tone: .gold, size: 40)
        StickerStar(tone: .pink, size: 28)
        StickerStar(tone: .blue, size: 20)
    }
    .padding()
}
