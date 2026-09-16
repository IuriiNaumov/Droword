import SwiftUI
import UIKit

enum AppIconStyle: String, CaseIterable, Identifiable {
    case classic
    case night
    case grain
    case neon
    case aurora
    case sun
    case ocean
    case forest
    case english
    case spanish
    case french
    case german
    case japanese
    case chinese
    case korean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return String(localized: "Main")
        case .night: return String(localized: "Night")
        case .grain: return String(localized: "Grain")
        case .neon: return String(localized: "Neon")
        case .aurora: return String(localized: "Aurora")
        case .sun: return String(localized: "Sun")
        case .ocean: return String(localized: "Ocean")
        case .forest: return String(localized: "Forest")
        case .english: return String(localized: "English")
        case .spanish: return String(localized: "Spanish")
        case .french: return String(localized: "French")
        case .german: return String(localized: "German")
        case .japanese: return String(localized: "Japanese")
        case .chinese: return String(localized: "Chinese")
        case .korean: return String(localized: "Korean")
        }
    }

    var alternateIconName: String? {
        switch self {
        case .classic: return nil
        case .night: return "AppIconNight"
        case .grain: return "AppIconGrain"
        case .neon: return "AppIconNeon"
        case .aurora: return "AppIconAurora"
        case .sun: return "AppIconSun"
        case .ocean: return "AppIconOcean"
        case .forest: return "AppIconForest"
        case .english: return "AppIconEnglish"
        case .spanish: return "AppIconSpanish"
        case .french: return "AppIconFrench"
        case .german: return "AppIconGerman"
        case .japanese: return "AppIconJapanese"
        case .chinese: return "AppIconChinese"
        case .korean: return "AppIconKorean"
        }
    }

    var requiresPremium: Bool { self != .classic }

    var accentColor: Color {
        switch self {
        case .classic: return Color(hex: "#5B9BD5")
        case .night: return Color(hex: "#A78BFA")
        case .grain: return Color(hex: "#8E8E93")
        case .neon: return Color(hex: "#32D74B")
        case .aurora: return Color(hex: "#7C3AED")
        case .sun: return Color(hex: "#E85D2C")
        case .ocean: return Color(hex: "#2EC4B6")
        case .forest: return Color(hex: "#58CC02")
        case .english: return Color(hex: "#3C3B6E")
        case .spanish: return Color(hex: "#C60B1E")
        case .french: return Color(hex: "#002395")
        case .german: return Color(hex: "#DD0000")
        case .japanese: return Color(hex: "#BC002D")
        case .chinese: return Color(hex: "#DE2910")
        case .korean: return Color(hex: "#0047A0")
        }
    }

    static let storageKey = "preferredAppIconStyle"

    static func resolved(_ raw: String) -> AppIconStyle {
        if raw == "ember" { return .sun }
        return AppIconStyle(rawValue: raw) ?? .classic
    }
}

struct AppIconArtwork: View {
    let style: AppIconStyle
    var size: CGFloat = 64

    var body: some View {
        Group {
            if let image = previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                        .fill(style == .classic ? Color.white : style.accentColor)
                    quotesMark
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
    }

    private var previewImage: UIImage? {
        if let name = style.alternateIconName, let image = UIImage(named: name) {
            return image
        }
        if style == .classic {
            return UIImage(named: "AppIconClassic")
        }
        return nil
    }

    private var quotesMark: some View {
        HStack(spacing: size * 0.08) {
            quoteGlyph
            quoteGlyph
        }
        .foregroundStyle(style == .classic ? Color(hex: "#1C1C1E") : Color.white)
    }

    private var quoteGlyph: some View {
        QuoteMarkShape()
            .frame(width: size * 0.22, height: size * 0.36)
    }
}

private struct QuoteMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r = min(w, h) * 0.42
        path.move(to: CGPoint(x: 0, y: r))
        path.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.46, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

enum AppIconChanger {
    static var currentStyle: AppIconStyle {
        let raw = UserDefaults.standard.string(forKey: AppIconStyle.storageKey) ?? AppIconStyle.classic.rawValue
        return AppIconStyle.resolved(raw)
    }

    static func apply(_ style: AppIconStyle, completion: @escaping (Bool) -> Void) {
        UserDefaults.standard.set(style.rawValue, forKey: AppIconStyle.storageKey)

        guard UIApplication.shared.supportsAlternateIcons else {
            completion(style == .classic)
            return
        }

        let name = style.alternateIconName

        if name != nil, !hasAlternateIcon(named: name!) {
            UIApplication.shared.setAlternateIconName(nil) { _ in
                completion(style == .classic)
            }
            return
        }

        UIApplication.shared.setAlternateIconName(name) { error in
            completion(error == nil || style == .classic)
        }
    }

    private static func hasAlternateIcon(named name: String) -> Bool {
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let alternate = icons["CFBundleAlternateIcons"] as? [String: Any]
        else { return false }
        return alternate[name] != nil
    }
}
