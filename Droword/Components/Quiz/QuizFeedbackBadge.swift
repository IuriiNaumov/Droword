import SwiftUI

struct QuizFeedbackBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
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
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(lockedText)
                    .font(themeStore.bold(13))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: 300, alignment: .leading)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.22))
            )
            .scaleEffect(bounce)

            Spacer(minLength: 0)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                bounce = 1.0
            }
        }
    }
}
