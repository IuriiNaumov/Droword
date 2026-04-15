import SwiftUI
import Combine

final class ThemeStore: ObservableObject {
    enum Palette: String, CaseIterable, Identifiable {
        case colorful
        case duolingo
        case sunset
        case glass
        var id: String { rawValue }
        var title: String {
            switch self {
            case .colorful: return "Droword"
            case .duolingo: return "Green Owl"
            case .sunset: return "Sunset"
            case .glass: return "Liquid Glass"
            }
        }
        var subtitle: String {
            switch self {
            case .colorful: return String(localized: "Warm and vibrant")
            case .duolingo: return String(localized: "Fresh green accent")
            case .sunset: return String(localized: "Cozy sunset vibes")
            case .glass: return String(localized: "Apple glass aesthetic")
            }
        }

        /// Whether this palette requires iOS 26+.
        var requiresIOS26: Bool { self == .glass }
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
        Colors(
            accentBlue: {
                switch palette {
                case .colorful: return Color("AccentBlue")
                case .duolingo: return Color(hex: "#89E219")
                case .sunset: return Color(hex: "#E8825C")
                case .glass: return Color(light: "#007AFF", dark: "#0A84FF")
                }
            }(),
            accentGreen: {
                switch palette {
                case .colorful: return Color("AccentGreen")
                case .duolingo: return Color(hex: "#7ED957")
                case .sunset: return Color(hex: "#8BBF7A")
                case .glass: return Color(light: "#34C759", dark: "#30D158")
                }
            }(),
            accentPurple: {
                switch palette {
                case .colorful: return Color("AccentPurple")
                case .duolingo: return Color(hex: "#D9A3FF")
                case .sunset: return Color(hex: "#C4889A")
                case .glass: return Color(light: "#AF52DE", dark: "#BF5AF2")
                }
            }(),
            accentPink: {
                switch palette {
                case .colorful: return Color("AccentPink")
                case .duolingo: return Color(hex: "#FF7E7E")
                case .sunset: return Color(hex: "#F0967A")
                case .glass: return Color(light: "#FF2D55", dark: "#FF375F")
                }
            }(),
            accentGold: {
                switch palette {
                case .colorful: return Color("AccentGold")
                case .duolingo: return Color(hex: "#2EC4B6")
                case .sunset: return Color(hex: "#F0A850")
                case .glass: return Color(light: "#FF9500", dark: "#FF9F0A")
                }
            }(),
            accentRed: {
                switch palette {
                case .colorful: return Color("AccentRed")
                case .duolingo: return Color(hex: "#FF4B4B")
                case .sunset: return Color(hex: "#E07060")
                case .glass: return Color(light: "#FF3B30", dark: "#FF453A")
                }
            }(),
            mainAccentColor: {
                switch palette {
                case .colorful: return Color("AccentBlue")
                case .duolingo: return Color(hex: "#58CC02")
                case .sunset: return Color(hex: "#E8825C")
                case .glass: return Color(light: "#007AFF", dark: "#0A84FF")
                }
            }(),
            appBg: {
                switch palette {
                case .colorful: return Color("AppBackground")
                case .duolingo: return Color(light: "#FFFFFF", dark: "#131F24")
                case .sunset: return Color(light: "#FFF0E8", dark: "#1C1315")
                case .glass: return Color(light: "#F2F2F7", dark: "#000000")
                }
            }(),
            cardBg: {
                switch palette {
                case .colorful: return Color("CardBackground")
                case .duolingo: return Color(light: "#F7F7F7", dark: "#1A2B32")
                case .sunset: return Color(light: "#FFF9F5", dark: "#2A2023")
                case .glass: return Color(light: "#F2F2F7", dark: "#1C1C1E")
                }
            }(),
            mainText: {
                switch palette {
                case .colorful: return Color("MainBlack")
                case .duolingo: return Color(light: "#4B4B4B", dark: "#FFFFFF")
                case .sunset: return Color(light: "#3D2C2C", dark: "#FFF0EA")
                case .glass: return Color(light: "#000000", dark: "#FFFFFF")
                }
            }(),
            secondaryText: {
                switch palette {
                case .colorful: return Color("MainGrey")
                case .duolingo: return Color(light: "#AFAFAF", dark: "#9CA3A8")
                case .sunset: return Color(light: "#B8A0A0", dark: "#9C8888")
                case .glass: return Color(light: "#8E8E93", dark: "#8E8E93")
                }
            }(),
            dividerColor: {
                switch palette {
                case .colorful: return Color("Divider")
                case .duolingo: return Color(light: "#E5E5E5", dark: "#37464F")
                case .sunset: return Color(light: "#F0DDD4", dark: "#3A2E32")
                case .glass: return Color(light: "#C6C6C8", dark: "#38383A")
                }
            }(),
            tabTint: {
                switch palette {
                case .colorful: return Color("AccentBlue")
                case .duolingo: return Color(hex: "#58CC02")
                case .sunset: return Color(hex: "#E8825C")
                case .glass: return Color(light: "#007AFF", dark: "#0A84FF")
                }
            }(),
            buttonShadow: {
                switch palette {
                case .colorful: return Color(hex: "#3D7ABF")
                case .duolingo: return Color(hex: "#46A302")
                case .sunset: return Color(hex: "#C46E4E")
                case .glass: return Color(hex: "#005EC4")
                }
            }(),
            iconGreen: {
                switch palette {
                case .colorful: return Color(hex: "#38B05B")
                case .duolingo: return Color(hex: "#58CC02")
                case .sunset: return Color(hex: "#8BBF7A")
                case .glass: return Color(light: "#34C759", dark: "#30D158")
                }
            }(),
            iconGold: {
                switch palette {
                case .colorful: return Color(hex: "#EBA130")
                case .duolingo: return Color(hex: "#2EC4B6")
                case .sunset: return Color(hex: "#F0A850")
                case .glass: return Color(light: "#FF9500", dark: "#FF9F0A")
                }
            }(),
            iconPurple: {
                switch palette {
                case .colorful: return Color(hex: "#7D71C8")
                case .duolingo: return Color(hex: "#CE82FF")
                case .sunset: return Color(hex: "#C4889A")
                case .glass: return Color(light: "#AF52DE", dark: "#BF5AF2")
                }
            }(),
            iconPink: {
                switch palette {
                case .colorful: return Color(hex: "#D86B94")
                case .duolingo: return Color(hex: "#FF7E7E")
                case .sunset: return Color(hex: "#F0967A")
                case .glass: return Color(light: "#FF2D55", dark: "#FF375F")
                }
            }(),
            iconBlue: {
                switch palette {
                case .colorful: return Color(hex: "#5B9BD5")
                case .duolingo: return Color(hex: "#89E219")
                case .sunset: return Color(hex: "#E8825C")
                case .glass: return Color(light: "#007AFF", dark: "#0A84FF")
                }
            }()
        )
    }

    init() {
        var raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Palette.colorful.rawValue
        if raw == "monochrome" { raw = "sunset" }
        // Fall back to colorful if glass was saved but device no longer supports it
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
        case .duolingo: return Color(light: "#E5F8D8", dark: "#243819")
        case .sunset: return Color(light: "#FFE8DD", dark: "#2E2226")
        case .glass: return Color(light: "#E3F0FF", dark: "#1C2A3D")
        }
    }

    var toastText: Color { accentBlue }

    var monoDark: Color {
        if isSunset { return Color(hex: "#E8825C") }
        if isGlass { return Color(light: "#8E8E93", dark: "#8E8E93") }
        return Color("MonoMedium")
    }

    var fontBold: String {
        isDuolingo ? ".AppleSystemUIFontRounded-Bold" : "Poppins-Bold"
    }

    var fontMedium: String {
        isDuolingo ? ".AppleSystemUIFontRounded-Medium" : "Poppins-Medium"
    }

    var fontRegular: String {
        isDuolingo ? ".AppleSystemUIFontRounded-Regular" : "Poppins-Regular"
    }

    func bold(_ size: CGFloat) -> Font {
        let s = size * fontScale
        return isDuolingo
            ? .system(size: s, weight: .bold, design: .rounded)
            : .custom("Poppins-Bold", size: s)
    }

    func medium(_ size: CGFloat) -> Font {
        let s = size * fontScale
        return isDuolingo
            ? .system(size: s, weight: .medium, design: .rounded)
            : .custom("Poppins-Medium", size: s)
    }

    func regular(_ size: CGFloat) -> Font {
        let s = size * fontScale
        return isDuolingo
            ? .system(size: s, weight: .regular, design: .rounded)
            : .custom("Poppins-Regular", size: s)
    }

    func resolvedTagColor(_ hex: String?) -> Color {
        guard !isSunset else { return Color(hex: "#E8825C") }
        guard !isGlass else { return accentBlue }
        guard let hex = hex, !hex.isEmpty else { return accentBlue }
        return Color(hex: hex)
    }

    func set(_ newPalette: Palette) { palette = newPalette }
}
// MARK: - Glass Card Modifier

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

