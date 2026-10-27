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
    case glass
    case owl
    case pixel
    case crystal
    case pride
    case wordInk
    case wordPaper
    case wordSky
    case wordLime
    case wordCoral

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
        case .glass: return String(localized: "Liquid Glass")
        case .owl: return String(localized: "Green Owl")
        case .pixel: return String(localized: "8-bit")
        case .crystal: return String(localized: "Crystal")
        case .pride: return "Pride"
        case .wordInk: return String(localized: "Ink")
        case .wordPaper: return String(localized: "Paper")
        case .wordSky: return String(localized: "Sky")
        case .wordLime: return String(localized: "Lime")
        case .wordCoral: return String(localized: "Coral")
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
        case .glass: return "AppIconGlass"
        case .owl: return "AppIconOwl"
        case .pixel: return "AppIconPixel"
        case .crystal: return "AppIconCrystal"
        case .pride: return "AppIconPride"
        case .wordInk: return "AppIconWordInk"
        case .wordPaper: return "AppIconWordPaper"
        case .wordSky: return "AppIconWordSky"
        case .wordLime: return "AppIconWordLime"
        case .wordCoral: return "AppIconWordCoral"
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
        case .glass: return Color(hex: "#007AFF")
        case .owl: return Color(hex: "#58CC02")
        case .pixel: return Color(hex: "#E03131")
        case .crystal: return Color(hex: "#7B6CFF")
        case .pride: return Color(hex: "#E40303")
        case .wordInk: return Color(hex: "#1C1C1E")
        case .wordPaper: return Color(hex: "#B9A98A")
        case .wordSky: return Color(hex: "#3D72C4")
        case .wordLime: return Color(hex: "#7CB518")
        case .wordCoral: return Color(hex: "#E8457C")
        }
    }

    static let storageKey = "preferredAppIconStyle"

    static var customizationCases: [AppIconStyle] { allCases }

    static func resolved(_ raw: String) -> AppIconStyle {
        if raw == "ember" { return .sun }
        if raw == "anime" { return .classic }
        if ["progress", "gay", "bi", "trans", "lesbian"].contains(raw) { return .pride }
        if ["hearts", "glasses", "dizzy", "sleepy"].contains(raw) { return .classic }
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
        quotes(color: style == .classic ? Color(hex: "#1C1C1E") : .white)
    }

    private func quotes(color: Color) -> some View {
        HStack(spacing: size * 0.08) {
            QuoteMarkShape()
                .fill(color)
                .frame(width: size * 0.22, height: size * 0.36)
            QuoteMarkShape()
                .fill(color)
                .frame(width: size * 0.22, height: size * 0.36)
        }
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

#Preview {
    HStack(spacing: 16) {
        AppIconArtwork(style: .classic, size: 72)
        AppIconArtwork(style: .owl, size: 72)
        AppIconArtwork(style: .pixel, size: 72)
        AppIconArtwork(style: .crystal, size: 72)
    }
    .padding()
}
