import SwiftUI

struct CustomizeIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    private let previewStyles: [AppIconStyle] = [.night, .classic, .sun]
    private var iconSize: CGFloat { size * 0.24 }

    var body: some View {
        ZStack {
            HaloRings(color: accent, size: size * 0.92)

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
