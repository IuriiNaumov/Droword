import SwiftUI
import Combine
import UIKit

final class ThemeStore: ObservableObject {
    enum Palette: String, CaseIterable, Identifiable {
        case colorful
        case duolingo
        case glass
        case custom

        var id: String { rawValue }

        static var pickerOrder: [Palette] {
            [.colorful, .duolingo, .glass, .custom]
        }

        var title: String {
            switch self {
            case .colorful: return String(localized: "Droword")
            case .duolingo: return String(localized: "Green Owl")
            case .glass: return String(localized: "Liquid Glass")
            case .custom: return String(localized: "Custom")
            }
        }

        var subtitle: String {
            switch self {
            case .colorful: return String(localized: "Warm and vibrant")
            case .duolingo: return String(localized: "White pages, gray cards, 3D buttons")
            case .glass: return String(localized: "Apple glass aesthetic")
            case .custom: return String(localized: "Pick your accent color")
            }
        }

        var requiresIOS26: Bool { self == .glass }

        var tileColors: [Color] {
            switch self {
            case .colorful: return [Color(hex: "#F6F7FF"), Color(hex: "#DDE4FA")]
            case .duolingo: return [Color(hex: "#FFFFFF"), Color(hex: "#F7F7F7"), Color(hex: "#58CC02")]
            case .glass: return [Color(hex: "#E8F1FF"), Color(hex: "#9BB7E8")]
            case .custom: return [Color(hex: "#F5F5F7"), Color(hex: "#C7C7CC")]
            }
        }

        var tileAccent: Color {
            switch self {
            case .colorful: return Color(hex: "#5B9BD5")
            case .duolingo: return Color(hex: "#58CC02")
            case .glass: return Color(hex: "#007AFF")
            case .custom: return Color(hex: "#5B9BD5")
            }
        }
    }

    @Published var palette: Palette {
        didSet {
            UserDefaults.standard.set(palette.rawValue, forKey: Self.storageKey)
            refreshCached()
        }
    }

    @Published var customAccentHex: String {
        didSet {
            UserDefaults.standard.set(customAccentHex, forKey: AppStorageKeys.customThemeAccentHex)
            if palette == .custom { refreshCached() }
        }
    }

    @Published var fontScale: CGFloat {
        didSet { UserDefaults.standard.set(fontScale, forKey: AppStorageKeys.fontScale) }
    }

    static private let storageKey = "appThemePalette"
    static let defaultCustomAccentHex = "#5B9BD5"

    static func rememberedPalette() -> Palette {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? Palette.colorful.rawValue
        return Palette(rawValue: raw) ?? .colorful
    }

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

    private func refreshCached() {
        cached = palette == .custom
            ? Self.buildCustomColors(hex: customAccentHex)
            : Self.buildColors(for: palette)
    }

    private static func buildColors(for palette: Palette) -> Colors {
        switch palette {
        case .custom:
            return buildCustomColors(hex: defaultCustomAccentHex)
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
        case .duolingo:
            return Colors(
                accentBlue: Color(hex: "#1CB0F6"),
                accentGreen: Color(hex: "#58CC02"),
                accentPurple: Color(hex: "#CE82FF"),
                accentPink: Color(hex: "#FF4B4B"),
                accentGold: Color(hex: "#FFC800"),
                accentRed: Color(hex: "#FF4B4B"),
                mainAccentColor: Color(hex: "#58CC02"),
                appBg: Color(light: "#FFFFFF", dark: "#131F24"),
                cardBg: Color(light: "#F7F7F7", dark: "#202F36"),
                mainText: Color(light: "#4B4B4B", dark: "#FFFFFF"),
                secondaryText: Color(light: "#777777", dark: "#AFB3B6"),
                dividerColor: Color(light: "#E5E5E5", dark: "#37464F"),
                tabTint: Color(hex: "#58CC02"),
                buttonShadow: Color(hex: "#58A700"),
                iconGreen: Color(hex: "#58CC02"),
                iconGold: Color(hex: "#FFC800"),
                iconPurple: Color(hex: "#CE82FF"),
                iconPink: Color(hex: "#FF4B4B"),
                iconBlue: Color(hex: "#1CB0F6")
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

    private static func buildCustomColors(hex: String) -> Colors {
        let ui = UIColor(Color(hex: hex.isEmpty ? defaultCustomAccentHex : hex))
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            h = 0.58; s = 0.55; b = 0.75
        }
        s = min(max(s, 0.45), 0.85)
        b = min(max(b, 0.55), 0.88)

        func hsba(_ hue: CGFloat, _ sat: CGFloat, _ bri: CGFloat) -> Color {
            let wrapped = (hue.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
            return Color(hue: wrapped, saturation: min(max(sat, 0), 1), brightness: min(max(bri, 0), 1))
        }

        func uiHSB(_ hue: CGFloat, _ sat: CGFloat, _ bri: CGFloat) -> UIColor {
            let wrapped = (hue.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
            return UIColor(hue: wrapped, saturation: min(max(sat, 0), 1), brightness: min(max(bri, 0), 1), alpha: 1)
        }

        let accent = hsba(h, s, b)
        let accentDark = hsba(h, min(s + 0.08, 1), max(b - 0.18, 0.35))
        let green = hsba(h + 0.28, max(s - 0.1, 0.35), min(b + 0.05, 0.85))
        let purple = hsba(h + 0.72, max(s - 0.05, 0.4), min(b, 0.8))
        let pink = hsba(h + 0.9, max(s - 0.05, 0.4), min(b + 0.05, 0.88))
        let gold = hsba(h + 0.12, max(s - 0.15, 0.4), min(b + 0.08, 0.9))
        let red = hsba(0.01, 0.72, 0.82)

        return Colors(
            accentBlue: accent,
            accentGreen: green,
            accentPurple: purple,
            accentPink: pink,
            accentGold: gold,
            accentRed: red,
            mainAccentColor: accent,
            appBg: Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? uiHSB(h, min(s * 0.35, 0.28), 0.10)
                    : uiHSB(h, min(s * 0.18, 0.14), 0.97)
            }),
            cardBg: Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? uiHSB(h, min(s * 0.22, 0.2), 0.16)
                    : uiHSB(h, min(s * 0.08, 0.06), 0.99)
            }),
            mainText: Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? uiHSB(h, min(s * 0.12, 0.1), 0.96)
                    : uiHSB(h, min(s * 0.35, 0.28), 0.18)
            }),
            secondaryText: Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? uiHSB(h, min(s * 0.15, 0.12), 0.68)
                    : uiHSB(h, min(s * 0.2, 0.16), 0.55)
            }),
            dividerColor: Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? uiHSB(h, min(s * 0.2, 0.16), 0.24)
                    : uiHSB(h, min(s * 0.15, 0.12), 0.88)
            }),
            tabTint: accent,
            buttonShadow: accentDark,
            iconGreen: green,
            iconGold: gold,
            iconPurple: purple,
            iconPink: pink,
            iconBlue: accent
        )
    }

    init() {
        var raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Palette.colorful.rawValue
        if raw == "monochrome" || raw == "night" || raw == "ocean" || raw == "sunset" || raw == "anime" || raw == "paper" || raw == "eightBit" {
            raw = Palette.colorful.rawValue
            UserDefaults.standard.set(raw, forKey: Self.storageKey)
        }
        if raw == "glass" {
            if #available(iOS 26, *) { } else { raw = "colorful" }
        }
        let storedHex = UserDefaults.standard.string(forKey: AppStorageKeys.customThemeAccentHex)
            ?? Self.defaultCustomAccentHex
        self.customAccentHex = storedHex
        let p = Palette(rawValue: raw) ?? .colorful
        self.palette = p
        self.cached = p == .custom
            ? Self.buildCustomColors(hex: storedHex)
            : Self.buildColors(for: p)
        let stored = UserDefaults.standard.double(forKey: AppStorageKeys.fontScale)
        self.fontScale = stored > 0 ? CGFloat(stored) : 1.0
    }

    var isDuolingo: Bool { palette == .duolingo }
    var isGlass: Bool { palette == .glass }
    var isCustom: Bool { palette == .custom }
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

    var sheetBg: Color { appBg }

    var controlFace: Color { isDuolingo ? appBg : cardBg }

    var secondaryButtonBg: Color {
        let page = appBg
        return Color(UIColor { traits in
            let resolved = UIColor(page).resolvedColor(with: traits)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
                return UIColor.systemGray5
            }
            let luma = (r + g + b) / 3
            if traits.userInterfaceStyle == .dark && luma < 0.15 {
                let lift: CGFloat = 0.10
                return UIColor(
                    red: min(r + lift, 1),
                    green: min(g + lift, 1),
                    blue: min(b + lift, 1),
                    alpha: a
                )
            }
            let amount: CGFloat = traits.userInterfaceStyle == .dark ? 0.08 : 0.055
            return UIColor(
                red: max(r - amount, 0),
                green: max(g - amount, 0),
                blue: max(b - amount, 0),
                alpha: a
            )
        })
    }

    var mainText: Color { cached.mainText }
    var secondaryText: Color { cached.secondaryText }
    var dividerColor: Color { cached.dividerColor }
    var tabTint: Color { cached.tabTint }
    var buttonShadow: Color { cached.buttonShadow }
    var iconAccent: Color {
        switch palette {
        case .colorful: return Color(hex: "#6A3AC4")
        case .duolingo: return accentBlue
        case .glass: return accentPurple
        case .custom: return accentPurple
        }
    }

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
        case .duolingo: return Color(light: "#D7FFB8", dark: "#243819")
        case .glass: return Color(light: "#E3F0FF", dark: "#1C2A3D")
        case .custom: return mainAccentColor.opacity(0.14)
        }
    }

    var toastText: Color { accentGreen }

    var controlRadius: CGFloat { isDuolingo ? 16 : DesignRadius.large }

    var cardRadius: CGFloat { isDuolingo ? 16 : DesignRadius.large }

    var chipRadius: CGFloat { isDuolingo ? 12 : DesignRadius.small }

    var successSoft: Color {
        isDuolingo ? Color(light: "#D7FFB8", dark: "#243819") : accentGreen.opacity(0.18)
    }
    var successStrong: Color { accentGreen }
    var errorSoft: Color {
        isDuolingo ? Color(light: "#FFDFE0", dark: "#3A1F22") : accentRed.opacity(0.18)
    }
    var errorStrong: Color { accentRed }
    var selectSoft: Color {
        isDuolingo ? Color(light: "#DDF4FF", dark: "#1A3340") : accentBlue.opacity(0.12)
    }
    var mutedControl: Color {
        isDuolingo ? Color(hex: "#E5E5E5") : secondaryText.opacity(0.4)
    }
    var mutedControlText: Color {
        isDuolingo ? Color(hex: "#AFAFAF") : .white
    }

    var monoDark: Color {
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

    func resolvedTagColor(_ hex: String?) -> Color {
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

    static func previewColors(for palette: Palette, customHex: String = defaultCustomAccentHex) -> PreviewColors {
        let c = palette == .custom
            ? buildCustomColors(hex: customHex)
            : buildColors(for: palette)
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

enum GlassShapeStyle {
    case roundedRect(CGFloat)
    case capsule
    case circle
}

struct GlassCardModifier: ViewModifier {
    let isGlass: Bool
    var cornerRadius: CGFloat = 20
    var shape: GlassShapeStyle = .roundedRect(20)
    var interactive: Bool = true

    init(isGlass: Bool, cornerRadius: CGFloat = 20, interactive: Bool = true) {
        self.isGlass = isGlass
        self.cornerRadius = cornerRadius
        self.shape = .roundedRect(cornerRadius)
        self.interactive = interactive
    }

    init(isGlass: Bool, shape: GlassShapeStyle, interactive: Bool = true) {
        self.isGlass = isGlass
        self.shape = shape
        self.interactive = interactive
        if case .roundedRect(let radius) = shape {
            self.cornerRadius = radius
        } else {
            self.cornerRadius = 20
        }
    }

    func body(content: Content) -> some View {
        if isGlass {
            if #available(iOS 26, *) {
                switch shape {
                case .roundedRect(let radius):
                    content.glassEffect(glass, in: .rect(cornerRadius: radius))
                case .capsule:
                    content.glassEffect(glass, in: .capsule)
                case .circle:
                    content.glassEffect(glass, in: .circle)
                }
            } else {
                content
            }
        } else {
            content
        }
    }

    @available(iOS 26, *)
    private var glass: Glass {
        interactive ? .regular.interactive() : .regular
    }
}
