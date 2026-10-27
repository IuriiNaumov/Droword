import SwiftUI

struct DictionaryIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        ZStack {
            StickerBook(size: size * 0.66, showsAccents: false)
                .offset(x: px * 0.08, y: py * 0.06)

            StickerTag(size: size * 0.32, showsAccents: false)
                .offset(x: -size * 0.30 + px * 0.12, y: size * 0.24 + py * 0.06)

            StickerStar(tone: .gold, size: size * 0.17)
                .offset(x: size * 0.32 + px * 0.1, y: -size * 0.28 + py * 0.05)

            StickerStar(tone: .pink, size: size * 0.11)
                .offset(x: -size * 0.33 + px * 0.06, y: -size * 0.26 + py * 0.04)

            StickerStar(tone: .purple, size: size * 0.09)
                .offset(x: size * 0.34 + px * 0.05, y: size * 0.26 + py * 0.03)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

#Preview {
    DictionaryIllustration(accent: .blue, size: 260, px: 0, py: 0)
}
