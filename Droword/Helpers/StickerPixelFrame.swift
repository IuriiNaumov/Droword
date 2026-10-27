import SwiftUI

struct StickerPixelFrame<Content: View>: View {
    @Environment(\.stickerStyle) private var style
    @Environment(\.stickerPixelated) private var pixelated
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection
    let size: CGFloat
    @ViewBuilder let content: Content
    @State private var cached: CGImage?

    private var cell: CGFloat { max(1.5, size / 26) }
    private var margin: CGFloat { (size * 0.12 / cell).rounded(.up) * cell }

    var body: some View {
        if style == .pixel && !pixelated {
            if let image = cached ?? pixelImage() {
                Image(decorative: image, scale: 1 / cell)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: size, height: size)
                    .onAppear { cached = image }
                    .onChange(of: colorScheme) { _, _ in cached = pixelImage() }
                    .onChange(of: layoutDirection) { _, _ in cached = pixelImage() }
            } else {
                content
            }
        } else {
            content
        }
    }

    private func pixelImage() -> CGImage? {
        let renderer = ImageRenderer(
            content: content
                .padding(margin)
                .environment(\.stickerStyle, .pixel)
                .environment(\.stickerPixelated, true)
                .environment(\.colorScheme, colorScheme)
                .environment(\.layoutDirection, layoutDirection)
        )
        renderer.scale = 1 / cell
        return renderer.cgImage
    }
}

#Preview {
    StickerPixelFrame(size: 72) {
        Circle()
            .sticker(StickerTone.gold, unit: 0.6)
            .frame(width: 72, height: 72)
    }
    .environment(\.stickerStyle, .pixel)
}
