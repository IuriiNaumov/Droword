import SwiftUI

struct StickerSymbol: View {
    let systemName: String
    var size: CGFloat = 28
    var color: Color = .primary

    var body: some View {
        Group {
            if let art = StickerArt(systemName: systemName) {
                StickerIcon(art: art, size: size)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.66, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) {
        StickerSymbol(systemName: "camera")
        StickerSymbol(systemName: "speaker.wave.2")
        StickerSymbol(systemName: "house", color: .purple)
        StickerSymbol(systemName: "trash", size: 76)
    }
    .padding()
}
