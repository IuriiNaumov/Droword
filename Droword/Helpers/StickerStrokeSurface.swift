import SwiftUI

struct StickerStrokeSurface<S: Shape>: View {
    @Environment(\.stickerStyle) private var style
    let shape: S
    let tone: StickerTone
    let width: CGFloat
    let unit: CGFloat
    let depth: CGFloat

    private func line(_ value: CGFloat, cap: CGLineCap = .round) -> StrokeStyle {
        StrokeStyle(lineWidth: value * unit, lineCap: cap, lineJoin: cap == .round ? .round : .miter)
    }

    var body: some View {
        let colors = StickerPalette.colors(tone.kind, style)
        let step = unit * depth
        ZStack {
            switch style {
            case .droword:
                shape.stroke(colors.side, style: line(width + 3 * depth)).offset(x: 3.5 * step, y: 4.5 * step)
                shape.stroke(colors.line, style: line(width + 3 * depth))
                shape.stroke(colors.face, style: line(width))
            case .duo:
                shape.stroke(colors.side, style: line(width + 3 * depth)).offset(y: 5 * step)
                shape.stroke(colors.face, style: line(width + 3 * depth))
            case .glass:
                shape.stroke(colors.side.opacity(0.3), style: line(width + 3 * depth)).blur(radius: 4 * unit).offset(y: 4 * unit)
                shape.stroke(LinearGradient(colors: [colors.face.opacity(0.78), colors.side.opacity(0.92)], startPoint: .top, endPoint: .bottom), style: line(width + 3 * depth))
                shape.stroke(Color.white.opacity(0.45), style: line(max(1, width * 0.35)))
            case .pixel:
                shape.stroke(colors.side, style: line(width + 7 * depth, cap: .square)).offset(x: 4 * step, y: 4 * step)
                shape.stroke(colors.line, style: line(width + 7 * depth, cap: .square))
                shape.stroke(colors.face, style: line(width, cap: .square))
            }
        }
    }
}

#Preview {
    Circle()
        .stickerStroke(StickerTone.blue, width: 8, unit: 1.2)
        .frame(width: 72, height: 72)
        .environment(\.stickerStyle, .droword)
}
