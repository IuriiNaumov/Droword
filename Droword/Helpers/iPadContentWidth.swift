import SwiftUI

private struct IPadContentWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSize

    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        if hSize == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

extension View {
    func iPadContentWidth(_ maxWidth: CGFloat = 700) -> some View {
        modifier(IPadContentWidthModifier(maxWidth: maxWidth))
    }
}
