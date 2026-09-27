import SwiftUI

private struct QuizCorrectFeedbackKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var quizCorrectFeedback: String? {
        get { self[QuizCorrectFeedbackKey.self] }
        set { self[QuizCorrectFeedbackKey.self] = newValue }
    }
}

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

struct QuizCorrectFeedbackBadge: View {
    @Environment(\.quizCorrectFeedback) private var correctFeedback
    @EnvironmentObject private var themeStore: ThemeStore

    var icon: String = "checkmark.circle.fill"

    var body: some View {
        let text = correctFeedback ?? DuoChaosCopy.correct()
        QuizFeedbackBadge(
            icon: icon,
            text: text,
            color: themeStore.successStrong
        )
        .id(text)
    }
}

#Preview {
    QuizFeedbackBadge(icon: "checkmark.circle", text: "Nice!", color: .green)
        .padding()
}
