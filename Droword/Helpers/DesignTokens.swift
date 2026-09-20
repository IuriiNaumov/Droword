import SwiftUI

enum DesignRadius {
    static let small: CGFloat = 14
    static let card: CGFloat = 24
    static let large: CGFloat = 28
    static let dialog: CGFloat = 32
}

enum DesignSpacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let section: CGFloat = 28
}

enum DesignMotion {
    static let toast = Animation.spring(response: 0.35, dampingFraction: 0.82)
    static let sheet = Animation.spring(response: 0.38, dampingFraction: 0.86)
    static let card = Animation.spring(response: 0.38, dampingFraction: 0.88)
    static let press = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(DesignMotion.press, value: configuration.isPressed)
    }
}

struct CardDepthModifier: ViewModifier {
    var cornerRadius: CGFloat = DesignRadius.card

    func body(content: Content) -> some View {
        content
    }
}

struct CleanCardModifier: ViewModifier {
    let isGlass: Bool
    let cardBg: Color
    var cornerRadius: CGFloat = DesignRadius.large

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isGlass ? Color.clear : cardBg)
            )
            .modifier(GlassCardModifier(isGlass: isGlass, cornerRadius: cornerRadius))
    }
}

extension View {
    func cardDepth(cornerRadius: CGFloat = DesignRadius.card) -> some View {
        modifier(CardDepthModifier(cornerRadius: cornerRadius))
    }

    func cleanCard(
        isGlass: Bool,
        cardBg: Color,
        cornerRadius: CGFloat = DesignRadius.large
    ) -> some View {
        modifier(CleanCardModifier(isGlass: isGlass, cardBg: cardBg, cornerRadius: cornerRadius))
    }

    func cleanCard(themeStore: ThemeStore, cornerRadius: CGFloat = DesignRadius.large) -> some View {
        cleanCard(isGlass: themeStore.isGlass, cardBg: themeStore.cardBg, cornerRadius: cornerRadius)
    }

    func modernSheet() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(DesignRadius.dialog)
    }
}
