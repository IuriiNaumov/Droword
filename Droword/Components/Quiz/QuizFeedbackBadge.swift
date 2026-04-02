import SwiftUI

struct QuizFeedbackBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var bounce: CGFloat = 0.6

    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(themeStore.mainText)
            Text(text)
                .font(themeStore.medium(14))
                .foregroundColor(themeStore.mainText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.3))
        )
        .scaleEffect(bounce)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            bounce = 0.6
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                bounce = 1.0
            }
        }
    }
}
