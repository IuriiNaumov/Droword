import SwiftUI

nonisolated enum StickerStyle: Sendable {
    case droword
    case duo
    case glass
    case pixel
}

nonisolated extension EnvironmentValues {
    @Entry var stickerStyle: StickerStyle = .droword
    @Entry var stickerPixelated: Bool = false
}

nonisolated struct StickerColors: Sendable {
    let face: Color
    let side: Color
    let highlight: Color
    let line: Color

    init(_ face: UInt32, _ side: UInt32, _ highlight: UInt32, _ line: UInt32) {
        self.face = Self.rgb(face)
        self.side = Self.rgb(side)
        self.highlight = Self.rgb(highlight)
        self.line = Self.rgb(line)
    }

    init(face: UInt32, side: UInt32, highlight: UInt32, line: Color) {
        self.face = Self.rgb(face)
        self.side = Self.rgb(side)
        self.highlight = Self.rgb(highlight)
        self.line = line
    }

    static func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

nonisolated enum StickerPalette {
    static func colors(_ kind: StickerTone.Kind, _ style: StickerStyle) -> StickerColors {
        switch style {
        case .droword: droword(kind)
        case .duo: duo(kind)
        case .glass: glass(kind)
        case .pixel: pixel(kind)
        }
    }

    private static func droword(_ kind: StickerTone.Kind) -> StickerColors {
        switch kind {
        case .purple: StickerColors(0x7C4FD6, 0x5A2FB0, 0xA684EA, 0x4A2596)
        case .blue: StickerColors(0x6564E8, 0x4544C4, 0x9796F5, 0x3534A8)
        case .gold: StickerColors(0xF2B54F, 0xD08A2A, 0xFFD98A, 0xB5751E)
        case .pink: StickerColors(0xE8558F, 0xC2346E, 0xF78DB5, 0xA82A5E)
        case .green: StickerColors(0x6CC074, 0x4E9A55, 0x9EDBA3, 0x3F8246)
        case .red: StickerColors(0xF0595C, 0xC93A3E, 0xFF999B, 0xA82D31)
        case .wood: StickerColors(0xC98A55, 0x9C6234, 0xE4B184, 0x7A4A24)
        case .ash: StickerColors(0xE2E1EA, 0xC6C4D3, 0xF4F3F8, 0xA9A6BA)
        case .paper: StickerColors(0xFFFDF6, 0xE4DDF5, 0xFFFFFF, 0x3534A8)
        case .slate: StickerColors(0x2A2840, 0x1C1A2C, 0x4A4660, 0x8B7AC8)
        }
    }

    private static func duo(_ kind: StickerTone.Kind) -> StickerColors {
        switch kind {
        case .purple: StickerColors(0xCE82FF, 0xA568CC, 0xE7C2FF, 0xA568CC)
        case .blue: StickerColors(0x1CB0F6, 0x1899D6, 0x8FDBFF, 0x1899D6)
        case .gold: StickerColors(0xFFC800, 0xE5A500, 0xFFE680, 0xE5A500)
        case .pink: StickerColors(0xFF86D0, 0xE06AB4, 0xFFC4E9, 0xE06AB4)
        case .green: StickerColors(0x58CC02, 0x58A700, 0xA5ED6E, 0x58A700)
        case .red: StickerColors(0xFF4B4B, 0xEA2B2B, 0xFFA3A3, 0xEA2B2B)
        case .wood: StickerColors(0xB87A4B, 0x8E5A33, 0xD9A983, 0x8E5A33)
        case .ash: StickerColors(0xE5E5E5, 0xCECECE, 0xF2F2F2, 0xCECECE)
        case .paper: StickerColors(0xFFFFFF, 0xDADADA, 0xFFFFFF, 0xDADADA)
        case .slate: StickerColors(0x202F36, 0x152028, 0x2A3D46, 0x3D5260)
        }
    }

    private static func glass(_ kind: StickerTone.Kind) -> StickerColors {
        let rim = Color.white.opacity(0.85)
        return switch kind {
        case .purple: StickerColors(face: 0xAF52DE, side: 0x8E3BB8, highlight: 0xE6C2F7, line: rim)
        case .blue: StickerColors(face: 0x007AFF, side: 0x0062CC, highlight: 0x8CC4FF, line: rim)
        case .gold: StickerColors(face: 0xFFB800, side: 0xD99A00, highlight: 0xFFE38A, line: rim)
        case .pink: StickerColors(face: 0xFF2D55, side: 0xD91E43, highlight: 0xFFA3B5, line: rim)
        case .green: StickerColors(face: 0x34C759, side: 0x248A3D, highlight: 0xA3E9B5, line: rim)
        case .red: StickerColors(face: 0xFF3B30, side: 0xD12B22, highlight: 0xFFA49F, line: rim)
        case .wood: StickerColors(face: 0xA2845E, side: 0x7F6545, highlight: 0xD3BFA4, line: rim)
        case .ash: StickerColors(face: 0xC7C7CC, side: 0xAEAEB2, highlight: 0xE9E9ED, line: rim)
        case .paper: StickerColors(face: 0xF7F7FA, side: 0xD1D1D6, highlight: 0xFFFFFF, line: rim)
        case .slate: StickerColors(face: 0x1C1C1E, side: 0x000000, highlight: 0x3A3A3C, line: rim)
        }
    }

    private static func pixel(_ kind: StickerTone.Kind) -> StickerColors {
        let ink: UInt32 = 0x1C140C
        return switch kind {
        case .purple: StickerColors(0x7B3FE4, ink, 0xB896F7, ink)
        case .blue: StickerColors(0x2563EB, ink, 0x86AEF7, ink)
        case .gold: StickerColors(0xF4B400, ink, 0xFFE27A, ink)
        case .pink: StickerColors(0xE0357F, ink, 0xF6A0C6, ink)
        case .green: StickerColors(0x2FA84F, ink, 0x8EDCA1, ink)
        case .red: StickerColors(0xE03131, ink, 0xF59999, ink)
        case .wood: StickerColors(0x9A6233, ink, 0xCB9C6E, ink)
        case .ash: StickerColors(0xBDB5A6, ink, 0xDDD6C8, ink)
        case .paper: StickerColors(0xFFFDF6, ink, 0xFFFFFF, ink)
        case .slate: StickerColors(0x1A2140, ink, 0x2A3458, ink)
        }
    }
}

nonisolated struct StickerPaint: ShapeStyle {
    enum Role: Sendable {
        case face
        case side
        case highlight
        case line
    }

    let kind: StickerTone.Kind
    let role: Role

    func resolve(in environment: EnvironmentValues) -> Color {
        let colors = StickerPalette.colors(kind, environment.stickerStyle)
        return switch role {
        case .face: colors.face
        case .side: colors.side
        case .highlight: colors.highlight
        case .line: colors.line
        }
    }
}
