import SwiftUI

enum HapticFeel: String, CaseIterable, Identifiable {
    case silk
    case soft
    case crisp
    case pop
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .silk: return String(localized: "Silk")
        case .soft: return String(localized: "Soft")
        case .crisp: return String(localized: "Crisp")
        case .pop: return String(localized: "Pop")
        case .off: return String(localized: "Off")
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .silk: return "whisper tap, almost velvet"
        case .soft: return "rounded, like a pillow press"
        case .crisp: return "clean iOS click"
        case .pop: return "short playful bump"
        case .off: return "no vibration"
        }
    }

    static var current: HapticFeel {
        HapticFeel(rawValue: UserDefaults.standard.string(forKey: AppStorageKeys.hapticFeel) ?? "") ?? .soft
    }
}
