import SwiftUI
import Combine
import UIKit

final class ThemeStore: ObservableObject {
    enum Palette: String, CaseIterable, Identifiable {
        case colorful
        case night
        case ocean
        case sunset
        case paper
        case duolingo
        case glass
        var id: String { rawValue }
        var title: String {
            switch self {
            case .colorful: return "Droword"
            case .night: return String(localized: "Night")
            case .ocean: return String(localized: "Ocean")
            case .sunset: return String(localized: "Sunset")
            case .paper: return String(localized: "Paper")
            case .duolingo: return "Green Owl"
            case .glass: return "Liquid Glass"
            }
        }
        var subtitle: String {
            switch self {
            case .colorful: return String(localized: "Warm and vibrant")
            case .night: return String(localized: "Deep black canvas")
            case .ocean: return String(localized: "Calm teal wash")
            case .sunset: return String(localized: "Cozy sunset vibes")
            case .paper: return String(localized: "Warm paper")
            case .duolingo: return String(localized: "Fresh green accent")
            case .glass: return String(localized: "Apple glass aesthetic")
            }
        }

        var requiresIOS26: Bool { self == .glass }

        var tileColors: [Color] {
            switch self {
            case .colorful: return [Color(hex: "#F6F7FF"), Color(hex: "#DDE4FA")]
            case .night: return [Color(hex: "#2A2438"), Color(hex: "#0B0B10")]
            case .ocean: return [Color(hex: "#7EE0D6"), Color(hex: "#0B3D4A")]
            case .sunset: return [Color(hex: "#FFB07A"), Color(hex: "#C2185B")]
            case .paper: return [Color(hex: "#FFF8EC"), Color(hex: "#E4D2B8")]
            case .duolingo: return [Color(hex: "#E5F8D8"), Color(hex: "#3FA006")]
            case .glass: return [Color(hex: "#E8F1FF"), Color(hex: "#9BB7E8")]
            }
        }

        var tileAccent: Color {
            switch self {
            case .colorful: return Color(hex: "#5B9BD5")
            case .night: return Color(hex: "#A78BFA")
            case .ocean: return Color(hex: "#2EC4B6")
            case .sunset: return Color(hex: "#E85D2C")
            case .paper: return Color(hex: "#C4784A")
            case .duolingo: return Color(hex: "#58CC02")
            case .glass: return Color(hex: "#007AFF")
            }
        }
    }

    @Published var palette: Palette {
        didSet {
            UserDefaults.standard.set(palette.rawValue, forKey: Self.storageKey)
            cached = Self.buildColors(for: palette)
        }
    }

    @Published var fontScale: CGFloat {
        didSet { UserDefaults.standard.set(fontScale, forKey: AppStorageKeys.fontScale) }
    }

    static private let storageKey = "appThemePalette"

    private struct Colors {
        let accentBlue: Color
        let accentGreen: Color
        let accentPurple: Color
        let accentPink: Color
        let accentGold: Color
        let accentRed: Color
        let mainAccentColor: Color
        let appBg: Color
        let cardBg: Color
        let mainText: Color
        let secondaryText: Color
        let dividerColor: Color
        let tabTint: Color
        let buttonShadow: Color
        let iconGreen: Color
        let iconGold: Color
        let iconPurple: Color
        let iconPink: Color
        let iconBlue: Color
    }

    private var cached: Colors

    private static func buildColors(for palette: Palette) -> Colors {
        switch palette {
        case .colorful:
            return Colors(
                accentBlue: Color("AccentBlue"),
                accentGreen: Color("AccentGreen"),
                accentPurple: Color("AccentPurple"),
                accentPink: Color("AccentPink"),
                accentGold: Color("AccentGold"),
                accentRed: Color("AccentRed"),
                mainAccentColor: Color("AccentBlue"),
                appBg: Color("AppBackground"),
                cardBg: Color("CardBackground"),
                mainText: Color("MainBlack"),
                secondaryText: Color("MainGrey"),
                dividerColor: Color("Divider"),
                tabTint: Color("AccentBlue"),
                buttonShadow: Color(hex: "#3D7ABF"),
                iconGreen: Color(hex: "#38B05B"),
                iconGold: Color(hex: "#EBA130"),
                iconPurple: Color(hex: "#7D71C8"),
                iconPink: Color(hex: "#D86B94"),
                iconBlue: Color(hex: "#5B9BD5")
            )
        case .night:
            return Colors(
                accentBlue: Color(hex: "#A78BFA"),
                accentGreen: Color(hex: "#34D399"),
                accentPurple: Color(hex: "#C4B5FD"),
                accentPink: Color(hex: "#F472B6"),
                accentGold: Color(hex: "#FBBF24"),
                accentRed: Color(hex: "#F87171"),
                mainAccentColor: Color(hex: "#A78BFA"),
                appBg: Color(light: "#14141A", dark: "#000000"),
                cardBg: Color(light: "#1C1C24", dark: "#1C1C1E"),
                mainText: Color(light: "#F4F4F8", dark: "#FFFFFF"),
                secondaryText: Color(hex: "#8E8E93"),
                dividerColor: Color(light: "#2C2C34", dark: "#2C2C2E"),
                tabTint: Color(hex: "#A78BFA"),
                buttonShadow: Color(hex: "#6D28D9"),
                iconGreen: Color(hex: "#34D399"),
                iconGold: Color(hex: "#FBBF24"),
                iconPurple: Color(hex: "#A78BFA"),
                iconPink: Color(hex: "#F472B6"),
                iconBlue: Color(hex: "#818CF8")
            )
        case .ocean:
            return Colors(
                accentBlue: Color(hex: "#2EC4B6"),
                accentGreen: Color(hex: "#7ED9A0"),
                accentPurple: Color(hex: "#7EB8D9"),
                accentPink: Color(hex: "#7ED4D0"),
                accentGold: Color(hex: "#F0C36A"),
                accentRed: Color(hex: "#E07070"),
                mainAccentColor: Color(hex: "#2EC4B6"),
                appBg: Color(light: "#E8F6F4", dark: "#0D1F24"),
                cardBg: Color(light: "#F4FFFD", dark: "#163038"),
                mainText: Color(light: "#12343A", dark: "#F4FFFD"),
                secondaryText: Color(light: "#6A9094", dark: "#7AA0A4"),
                dividerColor: Color(light: "#CDE8E4", dark: "#24444C"),
                tabTint: Color(hex: "#2EC4B6"),
                buttonShadow: Color(hex: "#1A8A82"),
                iconGreen: Color(hex: "#2EC4B6"),
                iconGold: Color(hex: "#F0C36A"),
                iconPurple: Color(hex: "#7EB8D9"),
                iconPink: Color(hex: "#7ED4D0"),
                iconBlue: Color(hex: "#2EC4B6")
            )
        case .sunset:
            return Colors(
                accentBlue: Color(hex: "#E8825C"),
                accentGreen: Color(hex: "#8BBF7A"),
                accentPurple: Color(hex: "#C4889A"),
                accentPink: Color(hex: "#F0967A"),
                accentGold: Color(hex: "#F0A850"),
                accentRed: Color(hex: "#E07060"),
                mainAccentColor: Color(hex: "#E8825C"),
                appBg: Color(light: "#FFF0E8", dark: "#1C1315"),
                cardBg: Color(light: "#FFF9F5", dark: "#2A2023"),
                mainText: Color(light: "#3D2C2C", dark: "#FFF0EA"),
                secondaryText: Color(light: "#B8A0A0", dark: "#9C8888"),
                dividerColor: Color(light: "#F0DDD4", dark: "#3A2E32"),
                tabTint: Color(hex: "#E8825C"),
                buttonShadow: Color(hex: "#C46E4E"),
                iconGreen: Color(hex: "#8BBF7A"),
                iconGold: Color(hex: "#F0A850"),
                iconPurple: Color(hex: "#C4889A"),
                iconPink: Color(hex: "#F0967A"),
                iconBlue: Color(hex: "#E8825C")
            )
        case .paper:
            return Colors(
                accentBlue: Color(hex: "#C4784A"),
                accentGreen: Color(hex: "#7A9A62"),
                accentPurple: Color(hex: "#A08070"),
                accentPink: Color(hex: "#C4887A"),
                accentGold: Color(hex: "#D4A017"),
                accentRed: Color(hex: "#B85C4A"),
                mainAccentColor: Color(hex: "#C4784A"),
                appBg: Color(light: "#F6F1E8", dark: "#1C1916"),
                cardBg: Color(light: "#FFFBF4", dark: "#2A2520"),
                mainText: Color(light: "#2C2416", dark: "#F6F1E8"),
                secondaryText: Color(light: "#A09080", dark: "#9C8C7C"),
                dividerColor: Color(light: "#E8DCC8", dark: "#3A342C"),
                tabTint: Color(hex: "#C4784A"),
                buttonShadow: Color(hex: "#8B5E3C"),
                iconGreen: Color(hex: "#7A9A62"),
                iconGold: Color(hex: "#D4A017"),
                iconPurple: Color(hex: "#A08070"),
                iconPink: Color(hex: "#C4887A"),
                iconBlue: Color(hex: "#C4784A")
            )
        case .duolingo:
            return Colors(
                accentBlue: Color(hex: "#89E219"),
                accentGreen: Color(hex: "#7ED957"),
                accentPurple: Color(hex: "#D9A3FF"),
                accentPink: Color(hex: "#FF7E7E"),
                accentGold: Color(hex: "#2EC4B6"),
                accentRed: Color(hex: "#FF4B4B"),
                mainAccentColor: Color(hex: "#58CC02"),
                appBg: Color(light: "#FFFFFF", dark: "#131F24"),
                cardBg: Color(light: "#F7F7F7", dark: "#1A2B32"),
                mainText: Color(light: "#4B4B4B", dark: "#FFFFFF"),
                secondaryText: Color(light: "#AFAFAF", dark: "#9CA3A8"),
                dividerColor: Color(light: "#E5E5E5", dark: "#37464F"),
                tabTint: Color(hex: "#58CC02"),
                buttonShadow: Color(hex: "#46A302"),
                iconGreen: Color(hex: "#58CC02"),
                iconGold: Color(hex: "#2EC4B6"),
                iconPurple: Color(hex: "#CE82FF"),
                iconPink: Color(hex: "#FF7E7E"),
                iconBlue: Color(hex: "#89E219")
            )
        case .glass:
            return Colors(
                accentBlue: Color(light: "#007AFF", dark: "#0A84FF"),
                accentGreen: Color(light: "#34C759", dark: "#30D158"),
                accentPurple: Color(light: "#AF52DE", dark: "#BF5AF2"),
                accentPink: Color(light: "#FF2D55", dark: "#FF375F"),
                accentGold: Color(light: "#FF9500", dark: "#FF9F0A"),
                accentRed: Color(light: "#FF3B30", dark: "#FF453A"),
                mainAccentColor: Color(light: "#007AFF", dark: "#0A84FF"),
                appBg: Color(light: "#F2F2F7", dark: "#000000"),
                cardBg: Color(light: "#F2F2F7", dark: "#1C1C1E"),
                mainText: Color(light: "#000000", dark: "#FFFFFF"),
                secondaryText: Color(light: "#6C6C70", dark: "#AEAEB2"),
                dividerColor: Color(light: "#C6C6C8", dark: "#38383A"),
                tabTint: Color(light: "#007AFF", dark: "#0A84FF"),
                buttonShadow: Color(hex: "#005EC4"),
                iconGreen: Color(light: "#34C759", dark: "#30D158"),
                iconGold: Color(light: "#FF9500", dark: "#FF9F0A"),
                iconPurple: Color(light: "#AF52DE", dark: "#BF5AF2"),
                iconPink: Color(light: "#FF2D55", dark: "#FF375F"),
                iconBlue: Color(light: "#007AFF", dark: "#0A84FF")
            )
        }
    }

    init() {
        var raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Palette.colorful.rawValue
        if raw == "monochrome" { raw = "sunset" }

        if raw == "glass" {
            if #available(iOS 26, *) { } else { raw = "colorful" }
        }
        let p = Palette(rawValue: raw) ?? .colorful
        self.palette = p
        self.cached = Self.buildColors(for: p)
        let stored = UserDefaults.standard.double(forKey: AppStorageKeys.fontScale)
        self.fontScale = stored > 0 ? CGFloat(stored) : 1.0
    }

    var isSunset: Bool { palette == .sunset }
    var isMonochrome: Bool { palette == .sunset }
    var isDuolingo: Bool { palette == .duolingo }
    var isGlass: Bool { palette == .glass }
    var title: String { palette.title }

    var accentBlue: Color { cached.accentBlue }
    var accentGreen: Color { cached.accentGreen }
    var accentPurple: Color { cached.accentPurple }
    var accentPink: Color { cached.accentPink }
    var accentGold: Color { cached.accentGold }

    var accentRed: Color { cached.accentRed }
    var mainAccentColor: Color { cached.mainAccentColor }
    var appBg: Color { cached.appBg }
    var cardBg: Color { cached.cardBg }
    var mainText: Color { cached.mainText }
    var secondaryText: Color { cached.secondaryText }
    var dividerColor: Color { cached.dividerColor }
    var tabTint: Color { cached.tabTint }
    var buttonShadow: Color { cached.buttonShadow }
    var iconGreen: Color { cached.iconGreen }
    var iconGold: Color { cached.iconGold }
    var iconPurple: Color { cached.iconPurple }
    var iconPink: Color { cached.iconPink }
    var iconBlue: Color { cached.iconBlue }

    var accentBlueSoft: Color { accentBlue.opacity(0.12) }

    var cardShadowColor: Color { .clear }
    var cardShadowRadius: CGFloat { 0 }

    var toastBg: Color {
        switch palette {
        case .colorful: return Color(light: "#E3E8FA", dark: "#262B47")
        case .night: return Color(light: "#2A2438", dark: "#1C1C24")
        case .ocean: return Color(light: "#D4F4F0", dark: "#163038")
        case .sunset: return Color(light: "#FFE8DD", dark: "#2E2226")
        case .paper: return Color(light: "#F0E6D4", dark: "#2A2520")
        case .duolingo: return Color(light: "#E5F8D8", dark: "#243819")
        case .glass: return Color(light: "#E3F0FF", dark: "#1C2A3D")
        }
    }

    var toastText: Color { accentGreen }

    var monoDark: Color {
        if isSunset { return Color(hex: "#E8825C") }
        if isGlass { return Color(light: "#8E8E93", dark: "#8E8E93") }
        return Color("MonoMedium")
    }

    var fontBold: String { "Poppins-Bold" }
    var fontMedium: String { "Poppins-Medium" }
    var fontRegular: String { "Poppins-Regular" }
    var fontDisplay: String { "Poppins-Black" }
    var fontSemiBold: String { "Poppins-SemiBold" }

    func bold(_ size: CGFloat) -> Font {
        customFont(name: fontBold, size: size)
    }

    func display(_ size: CGFloat) -> Font {
        customFont(name: fontDisplay, size: size)
    }

    func medium(_ size: CGFloat) -> Font {
        customFont(name: fontMedium, size: size)
    }

    func regular(_ size: CGFloat) -> Font {
        customFont(name: fontRegular, size: size)
    }

    private func customFont(name: String, size: CGFloat) -> Font {
        .custom(name, size: size * fontScale)
    }

    func uiFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let resolved: String = {
            switch weight {
            case .black, .heavy: return fontDisplay
            case .bold: return fontBold
            case .semibold: return fontSemiBold
            case .medium: return fontMedium
            default: return fontRegular
            }
        }()
        return uiFont(named: resolved, size: size * fontScale)
    }

    private func uiFont(named name: String, size: CGFloat) -> UIFont {
        if let primary = UIFont(name: name, size: size) {
            let fallback = UIFont.systemFont(ofSize: size)
            let descriptor = primary.fontDescriptor.addingAttributes([
                .cascadeList: [fallback.fontDescriptor]
            ])
            return UIFont(descriptor: descriptor, size: size)
        }
        #if DEBUG
        print("⚠️ Font missing: \(name) — falling back to system")
        #endif
        return UIFont.systemFont(ofSize: size, weight: .regular)
    }

    func iconCircleFill(colorScheme: ColorScheme) -> Color {
        isMonochrome
            ? mainText.opacity(colorScheme == .dark ? 0.7 : 0.75)
            : appBg
    }

    func resolvedTagColor(_ hex: String?) -> Color {
        guard !isSunset else { return Color(hex: "#E8825C") }
        guard !isGlass else { return accentBlue }
        guard let hex = hex, !hex.isEmpty else { return accentBlue }
        return Color(hex: hex)
    }

    func set(_ newPalette: Palette) { palette = newPalette }

    struct PreviewColors {
        let accentBlue: Color
        let accentGreen: Color
        let accentGold: Color
        let accentPink: Color
        let mainAccentColor: Color
        let appBg: Color
        let cardBg: Color
        let mainText: Color
        let secondaryText: Color
        let buttonShadow: Color
        let isGlass: Bool
        let isDuolingo: Bool

        func bold(_ size: CGFloat) -> Font {
            .custom("Poppins-Bold", size: size)
        }

        func medium(_ size: CGFloat) -> Font {
            .custom("Poppins-Medium", size: size)
        }

        func regular(_ size: CGFloat) -> Font {
            .custom("Poppins-Regular", size: size)
        }

        func display(_ size: CGFloat) -> Font {
            .custom("Poppins-Black", size: size)
        }
    }

    static func previewColors(for palette: Palette) -> PreviewColors {
        let c = buildColors(for: palette)
        return PreviewColors(
            accentBlue: c.accentBlue,
            accentGreen: c.accentGreen,
            accentGold: c.accentGold,
            accentPink: c.accentPink,
            mainAccentColor: c.mainAccentColor,
            appBg: c.appBg,
            cardBg: c.cardBg,
            mainText: c.mainText,
            secondaryText: c.secondaryText,
            buttonShadow: c.buttonShadow,
            isGlass: palette == .glass,
            isDuolingo: palette == .duolingo
        )
    }
}

struct GlassCardModifier: ViewModifier {
    let isGlass: Bool
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        if isGlass {
            if #available(iOS 26, *) {
                content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                content
            }
        } else {
            content
        }
    }
}
