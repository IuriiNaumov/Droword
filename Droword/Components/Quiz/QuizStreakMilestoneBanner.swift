import SwiftUI

/// Баннер-«ачивка» серии правильных ответов в квизе (появляется на 3, 5, 7, 10, …).
struct QuizStreakMilestoneBanner: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let streak: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundStyle(themeStore.accentRed)
            Text(text)
                .font(themeStore.bold(16))
                .foregroundStyle(themeStore.mainText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 14))
    }

    private var text: String {
        switch streak {
        case 3: return String(localized: "Nice start!")
        case 5: return String(localized: "On fire!")
        case 7: return String(localized: "Unstoppable!")
        case 10: return String(localized: "Perfect 10!")
        default: return String(localized: "x\(streak) streak!")
        }
    }
}
