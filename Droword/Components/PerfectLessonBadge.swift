import SwiftUI

/// Бейдж «Идеально!» для 100%-урока — пружинный пульсирующий значок с медалью.
struct PerfectLessonBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var scale: CGFloat = 0.3
    @State private var glow: CGFloat = 0.6

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "medal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(themeStore.accentGold)
            Text("Perfect lesson!")
                .font(themeStore.bold(16))
                .foregroundStyle(themeStore.mainText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        .background(
            Capsule()
                .fill(themeStore.accentGold.opacity(0.18))
                .overlay(
                    Capsule()
                        .stroke(themeStore.accentGold.opacity(glow), lineWidth: 1.5)
                )
        )
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glow = 1.0
            }
        }
    }
}
