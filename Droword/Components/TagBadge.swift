import SwiftUI

struct TagBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let text: String
    var body: some View {
        Text(text)
            .font(themeStore.medium(14))
            .foregroundColor(themeStore.mainText)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : Color.white.opacity(0.7))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 14))
    }
}
