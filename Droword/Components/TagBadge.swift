import SwiftUI

struct TagBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let text: String

    var body: some View {
        Text(text)
            .font(themeStore.medium(11))
            .foregroundStyle(themeStore.isGlass ? themeStore.mainText : themeStore.colorForTag(text))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        themeStore.isGlass
                            ? themeStore.colorForTag(text).opacity(0.28)
                            : themeStore.colorForTag(text).opacity(0.2)
                    )
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
    }
}

#Preview {
    TagBadge(text: "Travel")
        .padding()
        .environmentObject(ThemeStore())
}
