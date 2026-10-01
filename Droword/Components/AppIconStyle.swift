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
    case pride
    case wordInk
    case wordPaper
    case wordSky
    case wordLime
    case wordCoral
    case english
    case spanish
    case french
    case german
    case japanese
    case chinese
    case korean
    case portuguese
    case russian
    case ukrainian
    case mexican
    case turkish
    case greek
    case dutch
    case polish
    case swedish
    case norwegian
    case danish
    case finnish
    case vietnamese
    case indonesian
    case thai
    case hebrew
    case czech
    case romanian
    case hungarian

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
        case .glass: return "Liquid Glass"
        case .pride: return "Pride"
        case .wordInk: return String(localized: "Ink")
        case .wordPaper: return String(localized: "Paper")
        case .wordSky: return String(localized: "Sky")
        case .wordLime: return String(localized: "Lime")
        case .wordCoral: return String(localized: "Coral")
        case .english: return String(localized: "English")
        case .spanish: return String(localized: "Spanish")
        case .french: return String(localized: "French")
        case .german: return String(localized: "German")
        case .japanese: return String(localized: "Japanese")
        case .chinese: return String(localized: "Chinese")
        case .korean: return String(localized: "Korean")
        case .portuguese: return String(localized: "Portuguese")
        case .russian: return String(localized: "Russian")
        case .ukrainian: return String(localized: "Ukrainian")
        case .mexican: return String(localized: "Mexican")
        case .turkish: return String(localized: "Turkish")
        case .greek: return String(localized: "Greek")
        case .dutch: return String(localized: "Dutch")
        case .polish: return String(localized: "Polish")
        case .swedish: return String(localized: "Swedish")
        case .norwegian: return String(localized: "Norwegian")
        case .danish: return String(localized: "Danish")
        case .finnish: return String(localized: "Finnish")
        case .vietnamese: return String(localized: "Vietnamese")
        case .indonesian: return String(localized: "Indonesian")
        case .thai: return String(localized: "Thai")
        case .hebrew: return String(localized: "Hebrew")
        case .czech: return String(localized: "Czech")
        case .romanian: return String(localized: "Romanian")
        case .hungarian: return String(localized: "Hungarian")
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
        case .pride: return "AppIconPride"
        case .wordInk: return "AppIconWordInk"
        case .wordPaper: return "AppIconWordPaper"
        case .wordSky: return "AppIconWordSky"
        case .wordLime: return "AppIconWordLime"
        case .wordCoral: return "AppIconWordCoral"
        case .english: return "AppIconEnglish"
        case .spanish: return "AppIconSpanish"
        case .french: return "AppIconFrench"
        case .german: return "AppIconGerman"
        case .japanese: return "AppIconJapanese"
        case .chinese: return "AppIconChinese"
        case .korean: return "AppIconKorean"
        case .portuguese: return "AppIconPortuguese"
        case .russian: return "AppIconRussian"
        case .ukrainian: return "AppIconUkrainian"
        case .mexican: return "AppIconMexican"
        case .turkish: return "AppIconTurkish"
        case .greek: return "AppIconGreek"
        case .dutch: return "AppIconDutch"
        case .polish: return "AppIconPolish"
        case .swedish: return "AppIconSwedish"
        case .norwegian: return "AppIconNorwegian"
        case .danish: return "AppIconDanish"
        case .finnish: return "AppIconFinnish"
        case .vietnamese: return "AppIconVietnamese"
        case .indonesian: return "AppIconIndonesian"
        case .thai: return "AppIconThai"
        case .hebrew: return "AppIconHebrew"
        case .czech: return "AppIconCzech"
        case .romanian: return "AppIconRomanian"
        case .hungarian: return "AppIconHungarian"
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
        case .pride: return Color(hex: "#E40303")
        case .wordInk: return Color(hex: "#1C1C1E")
        case .wordPaper: return Color(hex: "#B9A98A")
        case .wordSky: return Color(hex: "#3D72C4")
        case .wordLime: return Color(hex: "#7CB518")
        case .wordCoral: return Color(hex: "#E8457C")
        case .english: return Color(hex: "#012169")
        case .spanish: return Color(hex: "#C60B1E")
        case .french: return Color(hex: "#002395")
        case .german: return Color(hex: "#DD0000")
        case .japanese: return Color(hex: "#BC002D")
        case .chinese: return Color(hex: "#DE2910")
        case .korean: return Color(hex: "#0047A0")
        case .portuguese: return Color(hex: "#046A38")
        case .russian: return Color(hex: "#0039A6")
        case .ukrainian: return Color(hex: "#0057B7")
        case .mexican: return Color(hex: "#006847")
        case .turkish: return Color(hex: "#E30A17")
        case .greek: return Color(hex: "#0D5EAF")
        case .dutch: return Color(hex: "#AE1C28")
        case .polish: return Color(hex: "#DC143C")
        case .swedish: return Color(hex: "#006AA7")
        case .norwegian: return Color(hex: "#BA0C2F")
        case .danish: return Color(hex: "#C60C30")
        case .finnish: return Color(hex: "#003580")
        case .vietnamese: return Color(hex: "#DA251D")
        case .indonesian: return Color(hex: "#CE1126")
        case .thai: return Color(hex: "#A51931")
        case .hebrew: return Color(hex: "#0038B8")
        case .czech: return Color(hex: "#11457E")
        case .romanian: return Color(hex: "#002B7F")
        case .hungarian: return Color(hex: "#CE2939")
        }
    }

    static let storageKey = "preferredAppIconStyle"

    private static let languageIcons: Set<AppIconStyle> = [
        .english, .spanish, .french, .german, .japanese, .chinese, .korean, .portuguese,
        .russian, .ukrainian, .mexican, .turkish, .greek, .dutch, .polish, .swedish,
        .norwegian, .danish, .finnish, .vietnamese, .indonesian, .thai, .hebrew,
        .czech, .romanian, .hungarian
    ]

    static var customizationCases: [AppIconStyle] {
        allCases.filter { !languageIcons.contains($0) }
    }

    static func resolved(_ raw: String) -> AppIconStyle {
        if raw == "ember" { return .sun }
        if raw == "anime" { return .classic }
        // Retired pride-flag variants → Pride
        if ["progress", "gay", "bi", "trans", "lesbian"].contains(raw) { return .pride }
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
            } else if usesDrawnFlag {
                ZStack {
                    drawnFlag
                    quotes(color: Color(hex: "#1C1C1E"))
                }
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

    private var usesDrawnFlag: Bool {
        flagBands != nil || drawnKind != nil
    }

    private enum DrawnKind {
        case turkish, greek, nordic, vietnamese, hebrew, czech
    }

    private var drawnKind: DrawnKind? {
        switch style {
        case .turkish: return .turkish
        case .greek: return .greek
        case .swedish, .norwegian, .danish, .finnish: return .nordic
        case .vietnamese: return .vietnamese
        case .hebrew: return .hebrew
        case .czech: return .czech
        default: return nil
        }
    }

    @ViewBuilder
    private var drawnFlag: some View {
        if let bands = flagBands {
            flagFill(colors: bands.colors, vertical: bands.vertical, weights: bands.weights)
        } else {
            switch style {
            case .turkish: turkishFlag
            case .greek: greekFlag
            case .swedish: nordicFlag(field: Color(hex: "#006AA7"), cross: Color(hex: "#FECC00"))
            case .norwegian: nordicFlag(field: Color(hex: "#BA0C2F"), cross: Color(hex: "#00205B"), outline: .white)
            case .danish: nordicFlag(field: Color(hex: "#C60C30"), cross: .white)
            case .finnish: nordicFlag(field: .white, cross: Color(hex: "#003580"))
            case .vietnamese: vietnamFlag
            case .hebrew: israelFlag
            case .czech: czechFlag
            default: Color.clear
            }
        }
    }

    private var turkishFlag: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color(hex: "#E30A17")
                Circle()
                    .fill(.white)
                    .frame(width: h * 0.52, height: h * 0.52)
                    .position(x: w * 0.36, y: h * 0.5)
                Circle()
                    .fill(Color(hex: "#E30A17"))
                    .frame(width: h * 0.42, height: h * 0.42)
                    .position(x: w * 0.44, y: h * 0.5)
                IconStar()
                    .fill(.white)
                    .frame(width: h * 0.26, height: h * 0.26)
                    .position(x: w * 0.64, y: h * 0.5)
            }
        }
    }

    private var flagBands: (colors: [Color], vertical: Bool, weights: [CGFloat]?)? {
        switch style {
        case .russian:
            return ([.white, Color(hex: "#0039A6"), Color(hex: "#D52B1E")], false, nil)
        case .ukrainian:
            return ([Color(hex: "#0057B7"), Color(hex: "#FFD700")], false, nil)
        case .mexican:
            return ([Color(hex: "#006847"), .white, Color(hex: "#CE1126")], true, nil)
        case .dutch:
            return ([Color(hex: "#AE1C28"), .white, Color(hex: "#21468B")], false, nil)
        case .polish:
            return ([.white, Color(hex: "#DC143C")], false, nil)
        case .indonesian:
            return ([Color(hex: "#CE1126"), .white], false, nil)
        case .romanian:
            return ([Color(hex: "#002B7F"), Color(hex: "#FCD116"), Color(hex: "#CE1126")], true, nil)
        case .hungarian:
            return ([Color(hex: "#CE2939"), .white, Color(hex: "#477050")], false, nil)
        case .thai:
            return ([
                Color(hex: "#A51931"), .white, Color(hex: "#2D2A4A"), .white, Color(hex: "#A51931")
            ], false, [1, 1, 2, 1, 1])
        default:
            return nil
        }
    }

    @ViewBuilder
    private func flagFill(colors: [Color], vertical: Bool, weights: [CGFloat]?) -> some View {
        GeometryReader { geo in
            let parts = weights ?? Array(repeating: 1, count: colors.count)
            let total = parts.reduce(0, +)
            if vertical {
                HStack(spacing: 0) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                        color.frame(width: geo.size.width * parts[index] / total)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                        color.frame(height: geo.size.height * parts[index] / total)
                    }
                }
            }
        }
    }

    private var greekFlag: some View {
        let blue = Color(hex: "#0D5EAF")
        return GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let stripe = h / 9
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { index in
                        (index.isMultiple(of: 2) ? blue : Color.white)
                            .frame(height: stripe)
                    }
                }
                ZStack {
                    blue
                    Rectangle().fill(.white).frame(width: w * 0.37, height: stripe)
                    Rectangle().fill(.white).frame(width: stripe, height: stripe * 5)
                }
                .frame(width: w * 0.37, height: stripe * 5)
            }
        }
    }

    private func nordicFlag(field: Color, cross: Color, outline: Color? = nil) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let x = w * 0.36
            let thick = h * (outline == nil ? 0.22 : 0.16)
            let outer = h * 0.28
            ZStack {
                field
                if let outline {
                    Rectangle().fill(outline).frame(width: outer, height: h).position(x: x, y: h / 2)
                    Rectangle().fill(outline).frame(width: w, height: outer).position(x: w / 2, y: h / 2)
                }
                Rectangle().fill(cross).frame(width: thick, height: h).position(x: x, y: h / 2)
                Rectangle().fill(cross).frame(width: w, height: thick).position(x: w / 2, y: h / 2)
            }
        }
    }

    private var vietnamFlag: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#DA251D")
                IconStar()
                    .fill(Color(hex: "#FFCD00"))
                    .frame(width: geo.size.height * 0.5, height: geo.size.height * 0.5)
            }
        }
    }

    private var israelFlag: some View {
        let blue = Color(hex: "#0038B8")
        return GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            ZStack {
                Color.white
                Rectangle().fill(blue).frame(width: w * 0.86, height: h * 0.1).position(x: w / 2, y: h * 0.18)
                Rectangle().fill(blue).frame(width: w * 0.86, height: h * 0.1).position(x: w / 2, y: h * 0.82)
                StarOfDavid()
                    .stroke(blue, lineWidth: max(1.2, h * 0.045))
                    .frame(width: h * 0.42, height: h * 0.42)
            }
        }
    }

    private var czechFlag: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .leading) {
                VStack(spacing: 0) {
                    Color.white
                    Color(hex: "#D7141A")
                }
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: w * 0.5, y: h / 2))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(Color(hex: "#11457E"))
            }
        }
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

private struct StarOfDavid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct IconStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.4
        var path = Path()
        for index in 0..<10 {
            let angle = (CGFloat(index) * 36 - 90) * .pi / 180
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
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
        AppIconArtwork(style: .pride, size: 72)
        AppIconArtwork(style: .ocean, size: 72)
    }
    .padding()
}
