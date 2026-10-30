import SwiftUI

struct BurningFlameIcon: View {
    var size: CGFloat = 14
    var monochrome: Bool = false
    var color: Color = StreakFireStyle.red

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(monochrome ? Color.white : color)
            .accessibilityHidden(true)
    }
}

enum StreakFireStyle {
    static let red = Color(hex: "#FF3B30")
}

#Preview {
    BurningFlameIcon(size: 24)
        .padding()
}
