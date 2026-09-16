import SwiftUI

struct QuizFeedbackBadge: View {
    @State private var bounce: CGFloat = 0.85
    @State private var lockedText: String

    let icon: String
    let color: Color

    init(icon: String, text: String, color: Color) {
        self.icon = icon
        self.color = color
        _lockedText = State(initialValue: text)
    }

    var body: some View {
        AppToastChrome(icon: icon, text: lockedText, tint: color, inset: false)
            .scaleEffect(bounce)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .onAppear {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                    bounce = 1.0
                }
            }
    }
}
