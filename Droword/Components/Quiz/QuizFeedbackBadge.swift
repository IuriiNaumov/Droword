import SwiftUI

struct QuizFeedbackBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var bounce: CGFloat = 0.7

    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(themeStore.mainText)
            Text(text)
                .font(themeStore.medium(14))
                .foregroundStyle(themeStore.mainText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.3))
        )
        .scaleEffect(bounce)
        .transition(.opacity)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                bounce = 1.0
            }
        }
    }
}
