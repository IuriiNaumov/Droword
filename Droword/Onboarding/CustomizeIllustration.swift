import SwiftUI

struct CustomizeIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    private let previewStyles: [AppIconStyle] = [.night, .classic, .wordLime]
    private var iconSize: CGFloat { size * 0.24 }

    var body: some View {
        ZStack {
            StickerStar(tone: .gold, size: size * 0.16)
                .offset(x: size * 0.33 + px * 0.1, y: -size * 0.25 + py * 0.05)

            StickerStar(tone: .pink, size: size * 0.11)
                .offset(x: -size * 0.34 + px * 0.06, y: -size * 0.22 + py * 0.04)

            StickerStar(tone: .purple, size: size * 0.13)
                .offset(x: -size * 0.28 + px * 0.05, y: size * 0.24 + py * 0.03)

            StickerStar(tone: .blue, size: size * 0.09)
                .offset(x: size * 0.30 + px * 0.05, y: size * 0.25 + py * 0.03)

            HStack(spacing: size * 0.045) {
                ForEach(Array(previewStyles.enumerated()), id: \.element) { index, style in
                    AppIconArtwork(style: style, size: iconSize)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
                        .rotationEffect(.degrees(index == 1 ? 0 : (index == 0 ? -8 : 8)))
                        .offset(y: index == 1 ? -size * 0.02 : size * 0.01)
                }
            }
            .offset(x: px * 0.08, y: py * 0.05)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

#Preview {
    CustomizeIllustration(accent: .orange, size: 220, px: 0, py: 0)
}
