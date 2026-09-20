import SwiftUI
import UIKit

struct LanguageCube: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let language: LanguageOption
    let isSelected: Bool
    let isBlocked: Bool
    let onTap: () -> Void

    @State private var internalPressedState: Bool = false

    private var accent: Color { themeStore.mainAccentColor }

    var body: some View {
        Button {
            guard !isBlocked else { return }
            onTap()
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Text(language.flag)
                        .font(.system(size: 28))

                    Text(language.name)
                        .font(themeStore.medium(13))
                        .foregroundStyle(isBlocked ? themeStore.secondaryText : themeStore.mainText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 88)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                        .fill(
                            isSelected
                                ? accent.opacity(0.14)
                                : (themeStore.isGlass ? Color.clear : themeStore.cardBg)
                        )
                )
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isSelected, cornerRadius: DesignRadius.card))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                        .background(Circle().fill(themeStore.cardBg).padding(1))
                        .offset(x: 2, y: -2)
                }
            }
            .scaleEffect(internalPressedState ? 0.97 : 1.0)
            .opacity(isBlocked ? 0.4 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isBlocked)
        .accessibilityLabel(Text(language.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .pressAction { pressed in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                internalPressedState = pressed
            }
        }
    }
}

extension Color {
    func darker(by amount: Double = 0.3) -> Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            red: max(r - amount, 0),
            green: max(g - amount, 0),
            blue: max(b - amount, 0),
            opacity: a
        )
    }
}

extension View {
    func pressAction(onChange: @escaping (Bool) -> Void) -> some View {
        modifier(PressActionsModifier(onChange: onChange))
    }
}

struct PressActionsModifier: ViewModifier {
    @State private var isPressed = false
    let onChange: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onChange(true)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onChange(false)
                    }
            )
    }
}

#Preview {
    LanguageCube(
        language: LanguageCatalog.availableLanguages[0],
        isSelected: true,
        isBlocked: false,
        onTap: {}
    )
    .padding()
    .environmentObject(ThemeStore())
}
