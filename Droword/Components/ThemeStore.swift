import SwiftUI
import Combine

final class ThemeStore: ObservableObject {
    enum Palette: String, CaseIterable, Identifiable {
        case colorful
        case duolingo
        case monochrome
        var id: String { rawValue }
        var title: String {
            switch self {
            case .colorful: return "Droword"
            case .duolingo: return "Green Owl"
            case .monochrome: return "Monochrome"
            }
        }
        var subtitle: String {
            switch self {
            case .colorful: return String(localized: "Warm and vibrant")
            case .duolingo: return String(localized: "Fresh green accent")
            case .monochrome: return String(localized: "Clean and minimal")
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
        Colors(
            accentBlue: {
                switch palette {
                case .colorful: return Color("AccentBlue")
                case .duolingo: return Color(hex: "#89E219")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            accentGreen: {
                switch palette {
                case .colorful: return Color("AccentGreen")
                case .duolingo: return Color(hex: "#7ED957")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            accentPurple: {
                switch palette {
                case .colorful: return Color("AccentPurple")
                case .duolingo: return Color(hex: "#D9A3FF")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            accentPink: {
                switch palette {
                case .colorful: return Color("AccentPink")
                case .duolingo: return Color(hex: "#FF7E7E")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            accentGold: {
                switch palette {
                case .colorful: return Color("AccentGold")
                case .duolingo: return Color(hex: "#2EC4B6")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            accentRed: {
                switch palette {
                case .colorful: return Color("AccentRed")
                case .duolingo: return Color(hex: "#FFB347")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            mainAccentColor: {
                switch palette {
                case .colorful: return Color("AccentBlue")
                case .duolingo: return Color(hex: "#58CC02")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            appBg: {
                switch palette {
                case .duolingo: return Color(light: "#FFFFFF", dark: "#131F24")
                default: return Color("AppBackground")
                }
            }(),
            cardBg: {
                switch palette {
                case .duolingo: return Color(light: "#F7F7F7", dark: "#1A2B32")
                default: return Color("CardBackground")
                }
            }(),
            mainText: {
                switch palette {
                case .duolingo: return Color(light: "#4B4B4B", dark: "#FFFFFF")
                default: return Color("MainBlack")
                }
            }(),
            secondaryText: {
                switch palette {
                case .duolingo: return Color(light: "#AFAFAF", dark: "#9CA3A8")
                default: return Color("MainGrey")
                }
            }(),
            dividerColor: {
                switch palette {
                case .duolingo: return Color(light: "#E5E5E5", dark: "#37464F")
                default: return Color("Divider")
                }
            }(),
            tabTint: {
                switch palette {
                case .colorful: return Color("AccentBlue")
                case .duolingo: return Color(hex: "#58CC02")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            buttonShadow: {
                switch palette {
                case .colorful: return Color(hex: "#3D7ABF")
                case .duolingo: return Color(hex: "#46A302")
                case .monochrome: return Color(hex: "#555555")
                }
            }(),
            iconGreen: {
                switch palette {
                case .colorful: return Color(hex: "#38B05B")
                case .duolingo: return Color(hex: "#58CC02")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            iconGold: {
                switch palette {
                case .colorful: return Color(hex: "#EBA130")
                case .duolingo: return Color(hex: "#2EC4B6")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            iconPurple: {
                switch palette {
                case .colorful: return Color(hex: "#7D71C8")
                case .duolingo: return Color(hex: "#CE82FF")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            iconPink: {
                switch palette {
                case .colorful: return Color(hex: "#D86B94")
                case .duolingo: return Color(hex: "#FF7E7E")
                case .monochrome: return Color("MonoMedium")
                }
            }(),
            iconBlue: {
                switch palette {
                case .colorful: return Color(hex: "#5B9BD5")
                case .duolingo: return Color(hex: "#89E219")
                case .monochrome: return Color("MonoMedium")
                }
            }()
        )
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Palette.colorful.rawValue
        let p = Palette(rawValue: raw) ?? .colorful
        self.palette = p
        self.cached = Self.buildColors(for: p)
        let stored = UserDefaults.standard.double(forKey: AppStorageKeys.fontScale)
        self.fontScale = stored > 0 ? CGFloat(stored) : 1.0
    }

    var isMonochrome: Bool { palette == .monochrome }
    var isDuolingo: Bool { palette == .duolingo }
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

    var toastBg: Color {
        switch palette {
        case .colorful: return Color(light: "#E3E8FA", dark: "#262B47")
        case .duolingo: return Color(light: "#E5F8D8", dark: "#243819")
        case .monochrome: return Color(light: "#EBEBEB", dark: "#383838")
        }
    }

    var toastText: Color { accentBlue }

    var monoDark: Color { Color("MonoMedium") }

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
        guard !isMonochrome else { return Color("MonoMedium") }
        guard let hex = hex, !hex.isEmpty else { return accentBlue }
        return Color(hex: hex)
    }

    func set(_ newPalette: Palette) { palette = newPalette }
}
