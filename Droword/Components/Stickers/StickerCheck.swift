import SwiftUI

struct StickerCheck: View {
    var tone: StickerTone = .purple
    var size: CGFloat = 80
    var depth: CGFloat = 1

    var body: some View {
        StickerPixelFrame(size: size) { art }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var art: some View {
        let unit = size / 120
        ZStack {
            StickerShape(glyph: .check).stickerStroke(tone, width: 18, unit: unit, depth: depth)
            StickerShape(glyph: .checkShine).shine(tone.highlight, width: 4.5, unit: unit)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    StickerCheck(size: 120)
        .padding()
}
