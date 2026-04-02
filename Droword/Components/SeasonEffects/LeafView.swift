import SwiftUI

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let f = s / 120.0
        let ox = rect.midX - s / 2
        let oy = rect.midY - s / 2

        var path = Path()

        path.move(to: CGPoint(x: 60 * f + ox, y: 15 * f + oy))
        path.addCurve(
            to: CGPoint(x: 100 * f + ox, y: 65 * f + oy),
            control1: CGPoint(x: 85 * f + ox, y: 20 * f + oy),
            control2: CGPoint(x: 105 * f + ox, y: 40 * f + oy)
        )
        path.addCurve(
            to: CGPoint(x: 60 * f + ox, y: 105 * f + oy),
            control1: CGPoint(x: 95 * f + ox, y: 90 * f + oy),
            control2: CGPoint(x: 70 * f + ox, y: 105 * f + oy)
        )
        path.addCurve(
            to: CGPoint(x: 20 * f + ox, y: 65 * f + oy),
            control1: CGPoint(x: 50 * f + ox, y: 105 * f + oy),
            control2: CGPoint(x: 25 * f + ox, y: 90 * f + oy)
        )
        path.addCurve(
            to: CGPoint(x: 60 * f + ox, y: 15 * f + oy),
            control1: CGPoint(x: 15 * f + ox, y: 40 * f + oy),
            control2: CGPoint(x: 35 * f + ox, y: 20 * f + oy)
        )
        path.closeSubpath()

        return path
    }
}

struct LeafVeinsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let f = s / 120.0
        let ox = rect.midX - s / 2
        let oy = rect.midY - s / 2

        var path = Path()

        path.move(to: CGPoint(x: 60 * f + ox, y: 20 * f + oy))
        path.addLine(to: CGPoint(x: 60 * f + ox, y: 105 * f + oy))

        let veins: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (60, 40, 80, 55),
            (60, 55, 85, 70),
            (60, 70, 80, 85),
            (60, 40, 40, 55),
            (60, 55, 35, 70),
            (60, 70, 40, 85),
        ]
        for v in veins {
            path.move(to: CGPoint(x: v.0 * f + ox, y: v.1 * f + oy))
            path.addLine(to: CGPoint(x: v.2 * f + ox, y: v.3 * f + oy))
        }

        return path
    }
}

struct LeafView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            LeafShape()
                .fill(Color(red: 0.788, green: 0.478, blue: 0.169))
            LeafVeinsShape()
                .stroke(Color(red: 0.545, green: 0.29, blue: 0.122), style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}
