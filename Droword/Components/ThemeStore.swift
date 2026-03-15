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
            case .duolingo: return "Duolingo"
            case .monochrome: return "Monochrome"
            }
        }
    }

    @Published var palette: Palette {
        didSet { UserDefaults.standard.set(palette.rawValue, forKey: Self.storageKey) }
    }

    static private let storageKey = "appThemePalette"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Palette.colorful.rawValue
        self.palette = Palette(rawValue: raw) ?? .colorful
    }

    var isMonochrome: Bool { palette == .monochrome }
    var isDuolingo: Bool { palette == .duolingo }
    var title: String { palette.title }

    // MARK: - Resolved accent colors

    var accentBlue: Color {
        switch palette {
        case .colorful: return Color("AccentBlue")
        case .duolingo: return Color(hex: "#1CB0F6")
        case .monochrome: return Color("MonoMedium")
        }
    }

    var accentGreen: Color {
        switch palette {
        case .colorful: return Color("AccentGreen")
        case .duolingo: return Color(hex: "#58CC02")
        case .monochrome: return Color("MonoMedium")
        }
    }

    var accentPurple: Color {
        switch palette {
        case .colorful: return Color("AccentPurple")
        case .duolingo: return Color(hex: "#CE82FF")
        case .monochrome: return Color("MonoMedium")
        }
    }

    var accentPink: Color {
        switch palette {
        case .colorful: return Color("AccentPink")
        case .duolingo: return Color(hex: "#FF4B4B")
        case .monochrome: return Color("MonoMedium")
        }
    }

    var accentGold: Color {
        switch palette {
        case .colorful: return Color("AccentGold")
        case .duolingo: return Color(hex: "#FFC800")
        case .monochrome: return Color("MonoMedium")
        }
    }

    var accentRed: Color {
        switch palette {
        case .colorful: return Color("AccentRed")
        case .duolingo: return Color(hex: "#FF9600")
        case .monochrome: return Color("MonoMedium")
        }
    }

    /// Darker mono accent — used for selected tags, stat cards, etc.
    var monoDark: Color { Color("MonoMedium") }

    /// For tag hex colors — returns mono gray when monochrome is active
    func resolvedTagColor(_ hex: String?) -> Color {
        guard !isMonochrome else { return Color("MonoMedium") }
        guard let hex = hex, !hex.isEmpty else { return accentBlue }
        return Color(hex: hex)
    }

    func set(_ newPalette: Palette) { palette = newPalette }
}

