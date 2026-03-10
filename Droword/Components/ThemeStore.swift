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

    func set(_ newPalette: Palette) { palette = newPalette }
}

