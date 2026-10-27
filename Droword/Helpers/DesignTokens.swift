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
    static let screenInset: CGFloat = 24
    static let titleTop: CGFloat = 12
    static let titleBottom: CGFloat = 12
    static let buttonGap: CGFloat = 8
    static let buttonVertical: CGFloat = 16
}

enum DesignChip {
    static let circle: CGFloat = 40
    static let circleCompact: CGFloat = 34
    static let emoji: CGFloat = 20
    static let emojiCompact: CGFloat = 17

    static func circleSize(compact: Bool) -> CGFloat {
        compact ? circleCompact : circle
    }

    static func emojiSize(compact: Bool) -> CGFloat {
        compact ? emojiCompact : emoji
    }
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
    @EnvironmentObject private var themeStore: ThemeStore
    var cornerRadius: CGFloat = DesignRadius.card

    func body(content: Content) -> some View {
        content.pixelFrame(themeStore, radius: cornerRadius)
    }
}

struct CleanCardModifier: ViewModifier {
    let isGlass: Bool
    let cardBg: Color
    var cornerRadius: CGFloat = DesignRadius.large
    var borderColor: Color? = nil
    var pixelInk: Color? = nil
    var pixelShadow: Color? = nil

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isGlass ? Color.clear : cardBg)
            )
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 2)
                }
            }
            .modifier(GlassCardModifier(isGlass: isGlass, cornerRadius: cornerRadius))
            .pixelFrame(active: pixelInk != nil, ink: pixelInk ?? .black, shadow: pixelShadow ?? .black, radius: cornerRadius)
    }
}

struct PixelFrameModifier: ViewModifier {
    var active: Bool
    var ink: Color
    var shadow: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        if active {
            content
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(ink, lineWidth: 2)
                }
                .background {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(shadow)
                        .offset(x: 4, y: 4)
                }
        } else {
            content
        }
    }
}

extension View {
    func cardDepth(cornerRadius: CGFloat = DesignRadius.card) -> some View {
        modifier(CardDepthModifier(cornerRadius: cornerRadius))
    }

    func cleanCard(
        isGlass: Bool,
        cardBg: Color,
        cornerRadius: CGFloat = DesignRadius.large,
        borderColor: Color? = nil,
        pixelInk: Color? = nil,
        pixelShadow: Color? = nil
    ) -> some View {
        modifier(CleanCardModifier(
            isGlass: isGlass,
            cardBg: cardBg,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            pixelInk: pixelInk,
            pixelShadow: pixelShadow
        ))
    }

    func cleanCard(themeStore: ThemeStore, cornerRadius: CGFloat? = nil) -> some View {
        let radius = cornerRadius ?? themeStore.cardRadius
        return cleanCard(
            isGlass: themeStore.isGlass,
            cardBg: themeStore.cardBg,
            cornerRadius: radius,
            borderColor: nil,
            pixelInk: themeStore.isPixel ? themeStore.pixelInk : nil,
            pixelShadow: themeStore.isPixel ? themeStore.pixelShadow : nil
        )
    }

    func pixelFrame(active: Bool, ink: Color, shadow: Color, radius: CGFloat) -> some View {
        modifier(PixelFrameModifier(active: active, ink: ink, shadow: shadow, radius: radius))
    }

    func pixelFrame(_ themeStore: ThemeStore, radius: CGFloat? = nil) -> some View {
        pixelFrame(
            active: themeStore.isPixel,
            ink: themeStore.pixelInk,
            shadow: themeStore.pixelShadow,
            radius: radius ?? themeStore.cardRadius
        )
    }

    func modernSheet() -> some View {
        modifier(ModernSheetModifier())
    }
}

private struct ModernSheetModifier: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.appAppearance) private var storedAppearance: String = AppAppearance.system.rawValue

    func body(content: Content) -> some View {
        content
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(themeStore.isPixel ? 0 : DesignRadius.dialog)
            .presentationBackground(themeStore.sheetBg)
            .preferredColorScheme(sheetScheme)
    }

    private var sheetScheme: ColorScheme {
        if let scheme = (AppAppearance(rawValue: storedAppearance) ?? .system).colorScheme {
            return scheme
        }
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }
}
