import SwiftUI

struct PracticeIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        HaloIcon(symbol: "bolt.fill", color: accent, size: size * 0.88)
            .offset(x: px * 0.08, y: py * 0.06)
            .allowsHitTesting(false)
    }
}
