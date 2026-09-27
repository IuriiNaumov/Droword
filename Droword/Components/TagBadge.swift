import SwiftUI

struct TagBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let text: String

    private var tagColor: Color { themeStore.colorForTag(text) }
    private var duo: Bool { themeStore.isDuolingo && !themeStore.isGlass }
    private var radius: CGFloat { themeStore.chipRadius }

    var body: some View {
        Text(BuiltInTag.displayName(text))
            .font(themeStore.medium(11))
            .foregroundStyle(duo ? Color.white : (themeStore.isGlass ? themeStore.mainText : tagColor))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background {
                if duo {
                    ZStack {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(darkerShade(of: tagColor, by: 0.16))
                            .offset(y: 2)
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(tagColor)
                    }
                } else {
                    Capsule(style: .continuous)
                        .fill(
                            themeStore.isGlass
                                ? tagColor.opacity(0.28)
                                : tagColor.opacity(0.2)
                        )
                }
            }
            .padding(.bottom, duo ? 2 : 0)
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
    }
}

#Preview {
    TagBadge(text: "Travel")
        .padding()
        .environmentObject(ThemeStore())
}
