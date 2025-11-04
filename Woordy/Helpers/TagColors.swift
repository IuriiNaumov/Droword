import SwiftUI

extension Color {
    init(hexRGB: UInt, alpha: Double = 1.0) {
        let r = Double((hexRGB >> 16) & 0xFF) / 255.0
        let g = Double((hexRGB >> 8) & 0xFF) / 255.0
        let b = Double(hexRGB & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    func darker(by percentage: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(.sRGB,
                     red: Double(max(r - CGFloat(percentage), 0)),
                     green: Double(max(g - CGFloat(percentage), 0)),
                     blue: Double(max(b - CGFloat(percentage), 0)),
                     opacity: Double(a))
    }
}
