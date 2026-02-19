import SwiftUI

func darkerShade(of color: Color, by percentage: Double = 0.2) -> Color {
    let uiColor = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return Color(.sRGB,
                 red: Double(max(r - CGFloat(percentage), 0)),
                 green: Double(max(g - CGFloat(percentage), 0)),
                 blue: Double(max(b - CGFloat(percentage), 0)),
                 opacity: Double(a))
}
