import SwiftUI

struct DictionaryIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        ZStack {
            HaloIcon(symbol: "textformat", color: accent, size: size * 0.88)
                .offset(x: px * 0.08, y: py * 0.06)

            Image(systemName: "tag.fill")
                .font(.system(size: size * 0.09, weight: .semibold))
                .foregroundStyle(accent)
                .offset(x: -size * 0.32 + px * 0.1, y: -size * 0.22 + py * 0.05)

            Image(systemName: "waveform")
                .font(.system(size: size * 0.09, weight: .semibold))
                .foregroundStyle(accent)
                .offset(x: size * 0.30 + px * 0.08, y: size * 0.20 + py * 0.04)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

#Preview {
    DictionaryIllustration(accent: .blue, size: 220, px: 0, py: 0)
}
