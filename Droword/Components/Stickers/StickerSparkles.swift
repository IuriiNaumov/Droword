import SwiftUI

struct StickerSparkles: View {
    var size: CGFloat = 150

    var body: some View {
        StickerPixelFrame(size: size) { art }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var art: some View {
        let unit = size / 120
        ZStack(alignment: .topLeading) {
            StickerStar(tone: .purple, size: size, depth: 1)
                .offset(x: -4 * unit, y: -2 * unit)
            StickerStar(tone: .gold, size: 43 * unit)
                .offset(x: 72 * unit, y: 4 * unit)
            StickerStar(tone: .pink, size: 36 * unit)
                .offset(x: 6 * unit, y: 74 * unit)
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }
}

#Preview {
    StickerSparkles(size: 168)
        .padding()
}
