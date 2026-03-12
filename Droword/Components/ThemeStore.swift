import SwiftUI
import Combine

final class ThemeStore: ObservableObject {
    enum Palette: String, CaseIterable, Identifiable {
        case colorful
        case monochrome
        var id: String { rawValue }
        var title: String { self == .monochrome ? "Monochrome" : "Colorful" }
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
    var title: String { palette.title }

    // MARK: - Resolved accent colors (mono-aware)

    var accentBlue: Color   { isMonochrome ? Color("MonoMedium") : Color("AccentBlue") }
    var accentGreen: Color  { isMonochrome ? Color("MonoMedium") : Color("AccentGreen") }
    var accentPurple: Color { isMonochrome ? Color("MonoMedium") : Color("AccentPurple") }
    var accentPink: Color   { isMonochrome ? Color("MonoMedium") : Color("AccentPink") }
    var accentGold: Color   { isMonochrome ? Color("MonoMedium") : Color("AccentGold") }
    var accentRed: Color    { isMonochrome ? Color("MonoMedium") : Color("AccentRed") }

    /// Darker mono accent — used for selected tags, stat cards, etc.
    var monoDark: Color { Color("MonoMedium") }

    /// For tag hex colors — returns mono gray when monochrome is active
    func resolvedTagColor(_ hex: String?) -> Color {
        guard !isMonochrome else { return Color("MonoMedium") }
        guard let hex = hex, !hex.isEmpty else { return Color("AccentBlue") }
        return Color(hex: hex)
    }

    func set(_ newPalette: Palette) { palette = newPalette }
}

