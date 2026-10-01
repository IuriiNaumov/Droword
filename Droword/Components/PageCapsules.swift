import SwiftUI

struct PageCapsules: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let count: Int
    let selection: Int
    var activeColor: Color? = nil
    var glass: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                capsule(active: index == selection)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selection)
    }

    private var useGlass: Bool { glass || themeStore.isGlass }

    private func capsule(active: Bool) -> some View {
        Capsule(style: .continuous)
            .fill(fill(active: active))
            .frame(width: active ? 18 : 8, height: 8)
            .modifier(GlassCardModifier(isGlass: useGlass, shape: .capsule))
    }

    private func fill(active: Bool) -> Color {
        let accent = activeColor ?? themeStore.mainAccentColor
        if useGlass {
            return active
                ? accent.opacity(colorScheme == .dark ? 0.45 : 0.35)
                : themeStore.secondaryText.opacity(0.18)
        }
        return active ? accent : themeStore.secondaryText.opacity(0.25)
    }
}
