import SwiftUI

enum ModalIconKind: String, CaseIterable, Identifiable {
    case trash
    case warning
    case success
    case offline
    case duplicate
    case idea
    case celebrate

    var id: String { rawValue }

    static func from(systemName: String) -> ModalIconKind {
        switch systemName {
        case "trash", "trash.fill": return .trash
        case "exclamationmark.triangle.fill", "exclamationmark.triangle": return .warning
        case "checkmark.circle.fill", "checkmark.circle", "checkmark": return .success
        case "wifi.slash": return .offline
        case "doc.on.doc", "doc.on.doc.fill": return .duplicate
        case "lightbulb", "lightbulb.fill": return .idea
        default:
            if systemName.contains("trash") { return .trash }
            if systemName.contains("wifi") { return .offline }
            if systemName.contains("check") { return .success }
            if systemName.contains("exclamation") { return .warning }
            return .warning
        }
    }
}

struct ModalIconView: View {
    let kind: ModalIconKind
    var color: Color
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            SoftBlob(color: color, size: size)
            glyph
                .frame(width: size * 0.42, height: size * 0.42)
        }
        .frame(width: size, height: size * 0.92)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var glyph: some View {
        switch kind {
        case .trash:
            ModalTrashGlyph(color: color)
        case .warning:
            ModalWarningGlyph(color: color)
        case .success:
            ModalSuccessGlyph(color: color)
        case .offline:
            ModalOfflineGlyph(color: color)
        case .duplicate:
            ModalDuplicateGlyph(color: color)
        case .idea:
            Image(systemName: "lightbulb.fill")
                .font(.system(size: size * 0.28, weight: .semibold))
                .foregroundStyle(color)
        case .celebrate:
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.28, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

private struct ModalTrashGlyph: View {
    var color: Color
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var lid = Path()
            lid.move(to: CGPoint(x: w * 0.18, y: h * 0.28))
            lid.addLine(to: CGPoint(x: w * 0.82, y: h * 0.28))
            context.stroke(lid, with: .color(color), style: StrokeStyle(lineWidth: w * 0.08, lineCap: .round))

            var handle = Path()
            handle.addRoundedRect(
                in: CGRect(x: w * 0.38, y: h * 0.14, width: w * 0.24, height: h * 0.12),
                cornerSize: CGSize(width: 3, height: 3)
            )
            context.stroke(handle, with: .color(color), style: StrokeStyle(lineWidth: w * 0.06))

            var body = Path()
            body.move(to: CGPoint(x: w * 0.24, y: h * 0.34))
            body.addLine(to: CGPoint(x: w * 0.3, y: h * 0.88))
            body.addLine(to: CGPoint(x: w * 0.7, y: h * 0.88))
            body.addLine(to: CGPoint(x: w * 0.76, y: h * 0.34))
            body.closeSubpath()
            context.fill(body, with: .color(color.opacity(0.92)))

            for x in [0.4, 0.5, 0.6] as [CGFloat] {
                var line = Path()
                line.move(to: CGPoint(x: w * x, y: h * 0.46))
                line.addLine(to: CGPoint(x: w * x, y: h * 0.74))
                context.stroke(line, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: w * 0.05, lineCap: .round))
            }
        }
    }
}

private struct ModalWarningGlyph: View {
    var color: Color
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var tri = Path()
            tri.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
            tri.addLine(to: CGPoint(x: w * 0.9, y: h * 0.86))
            tri.addLine(to: CGPoint(x: w * 0.1, y: h * 0.86))
            tri.closeSubpath()
            context.fill(tri, with: .color(color))

            var bang = Path()
            bang.addRoundedRect(
                in: CGRect(x: w * 0.45, y: h * 0.34, width: w * 0.1, height: h * 0.28),
                cornerSize: CGSize(width: 2, height: 2)
            )
            context.fill(bang, with: .color(.white.opacity(0.92)))
            var dot = Path()
            dot.addEllipse(in: CGRect(x: w * 0.44, y: h * 0.68, width: w * 0.12, height: h * 0.1))
            context.fill(dot, with: .color(.white.opacity(0.92)))
        }
    }
}

private struct ModalSuccessGlyph: View {
    var color: Color
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var circle = Path()
            circle.addEllipse(in: CGRect(x: w * 0.08, y: h * 0.08, width: w * 0.84, height: h * 0.84))
            context.fill(circle, with: .color(color))

            var check = Path()
            check.move(to: CGPoint(x: w * 0.28, y: h * 0.52))
            check.addLine(to: CGPoint(x: w * 0.44, y: h * 0.68))
            check.addLine(to: CGPoint(x: w * 0.72, y: h * 0.34))
            context.stroke(check, with: .color(.white), style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct ModalOfflineGlyph: View {
    var color: Color
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            for (r, opacity) in [(0.42, 0.35), (0.28, 0.55)] as [(CGFloat, Double)] {
                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: w * 0.5, y: h * 0.62),
                    radius: w * r,
                    startAngle: .degrees(210),
                    endAngle: .degrees(330),
                    clockwise: false
                )
                context.stroke(arc, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: w * 0.08, lineCap: .round))
            }
            var dot = Path()
            dot.addEllipse(in: CGRect(x: w * 0.42, y: h * 0.68, width: w * 0.16, height: h * 0.16))
            context.fill(dot, with: .color(color))

            var slash = Path()
            slash.move(to: CGPoint(x: w * 0.22, y: h * 0.78))
            slash.addLine(to: CGPoint(x: w * 0.78, y: h * 0.22))
            context.stroke(slash, with: .color(color), style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round))
        }
    }
}

private struct ModalDuplicateGlyph: View {
    var color: Color
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var back = Path()
            back.addRoundedRect(
                in: CGRect(x: w * 0.28, y: h * 0.12, width: w * 0.52, height: h * 0.62),
                cornerSize: CGSize(width: w * 0.08, height: w * 0.08)
            )
            context.fill(back, with: .color(color.opacity(0.45)))

            var front = Path()
            front.addRoundedRect(
                in: CGRect(x: w * 0.16, y: h * 0.28, width: w * 0.52, height: h * 0.62),
                cornerSize: CGSize(width: w * 0.08, height: w * 0.08)
            )
            context.fill(front, with: .color(color))
            for y in [0.46, 0.58, 0.7] as [CGFloat] {
                var line = Path()
                line.move(to: CGPoint(x: w * 0.28, y: h * y))
                line.addLine(to: CGPoint(x: w * 0.56, y: h * y))
                context.stroke(line, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: w * 0.05, lineCap: .round))
            }
        }
    }
}

#Preview("Modal icons") {
    HStack(spacing: 20) {
        ForEach(ModalIconKind.allCases) { kind in
            VStack {
                ModalIconView(kind: kind, color: .orange, size: 72)
                Text(kind.rawValue).font(.caption2)
            }
        }
    }
    .padding()
}
