import SwiftUI

// MARK: - Snowflake shape (SVG-based)
struct SnowflakeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let s = min(rect.width, rect.height)
        // Scale factor: SVG is 120x120, map to s
        let f = s / 120.0

        var path = Path()

        // 4 main arms (thick lines in SVG)
        let arms: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 60, y: 15), CGPoint(x: 60, y: 105)),   // vertical
            (CGPoint(x: 15, y: 60), CGPoint(x: 105, y: 60)),   // horizontal
            (CGPoint(x: 25, y: 25), CGPoint(x: 95, y: 95)),    // diagonal
            (CGPoint(x: 95, y: 25), CGPoint(x: 25, y: 95)),    // diagonal
        ]

        for arm in arms {
            path.move(to: CGPoint(x: arm.0.x * f, y: arm.0.y * f))
            path.addLine(to: CGPoint(x: arm.1.x * f, y: arm.1.y * f))
        }

        // Branch tips
        let branches: [(CGPoint, CGPoint)] = [
            // Top
            (CGPoint(x: 60, y: 15), CGPoint(x: 52, y: 28)),
            (CGPoint(x: 60, y: 15), CGPoint(x: 68, y: 28)),
            // Right
            (CGPoint(x: 105, y: 60), CGPoint(x: 92, y: 52)),
            (CGPoint(x: 105, y: 60), CGPoint(x: 92, y: 68)),
            // Bottom
            (CGPoint(x: 60, y: 105), CGPoint(x: 52, y: 92)),
            (CGPoint(x: 60, y: 105), CGPoint(x: 68, y: 92)),
            // Left
            (CGPoint(x: 15, y: 60), CGPoint(x: 28, y: 52)),
            (CGPoint(x: 15, y: 60), CGPoint(x: 28, y: 68)),
        ]

        for branch in branches {
            path.move(to: CGPoint(x: branch.0.x * f, y: branch.0.y * f))
            path.addLine(to: CGPoint(x: branch.1.x * f, y: branch.1.y * f))
        }

        // Offset to center
        let offset = CGPoint(x: cx - s / 2, y: cy - s / 2)
        return path.offsetBy(dx: offset.x, dy: offset.y)
    }
}

struct SnowflakeView: View {
    let size: CGFloat

    var body: some View {
        SnowflakeShape()
            .stroke(Color(red: 0.3, green: 0.65, blue: 1.0), style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
            .frame(width: size, height: size)
    }
}
