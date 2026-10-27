import SwiftUI

struct StickerSurface<S: Shape>: View {
    @Environment(\.stickerStyle) private var style
    let shape: S
    let tone: StickerTone
    let unit: CGFloat
    let depth: CGFloat

    var body: some View {
        let colors = StickerPalette.colors(tone.kind, style)
        let step = unit * depth
        ZStack {
            switch style {
            case .droword:
                shape.fill(colors.side).offset(x: 3.5 * step, y: 4.5 * step)
                shape.fill(colors.face)
                shape.stroke(colors.line, style: StrokeStyle(lineWidth: 1.5 * step, lineJoin: .round))
            case .duo:
                shape.fill(colors.side).offset(y: 5 * step)
                shape.fill(colors.face)
                if tone.kind == .paper || tone.kind == .slate {
                    shape.stroke(colors.side, style: StrokeStyle(lineWidth: 2.5 * step, lineJoin: .round))
                }
            case .glass:
                shape.fill(colors.side.opacity(0.3)).blur(radius: 4 * unit).offset(y: 4 * unit)
                shape.fill(LinearGradient(colors: [colors.face.opacity(0.78), colors.side.opacity(0.92)], startPoint: .top, endPoint: .bottom))
                shape.fill(LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0)], startPoint: .top, endPoint: .center))
                shape.stroke(colors.line, style: StrokeStyle(lineWidth: 1.6 * step, lineJoin: .round))
            case .pixel:
                shape.fill(colors.side).offset(x: 4 * step, y: 4 * step)
                shape.fill(colors.face)
                shape.stroke(colors.line, style: StrokeStyle(lineWidth: 3.5 * step, lineJoin: .miter))
            }
        }
    }
}

#Preview {
    Circle()
        .sticker(StickerTone.purple, unit: 1.2)
        .frame(width: 72, height: 72)
        .environment(\.stickerStyle, .droword)
}
