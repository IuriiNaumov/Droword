import SwiftUI

struct SettingsBackButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            BackArrowShape()
                .stroke(themeStore.mainText, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 10, height: 18)
                .contentShape(Rectangle().size(width: 44, height: 44))
        }
        .buttonStyle(.plain)
    }
}

private struct BackArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}
