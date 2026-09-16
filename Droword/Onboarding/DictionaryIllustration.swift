import SwiftUI

struct DictionaryIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        HaloIcon(symbol: "textformat", color: accent, size: size * 0.88)
            .offset(x: px * 0.08, y: py * 0.06)
            .allowsHitTesting(false)
    }
}
