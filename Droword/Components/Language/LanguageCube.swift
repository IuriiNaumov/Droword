import SwiftUI
import UIKit

struct LanguageCube: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeStore: ThemeStore
    let language: LanguageOption
    let isSelected: Bool
    let isBlocked: Bool
    let onTap: () -> Void

    @State private var internalPressedState: Bool = false

    private var resolvedColor: Color {
        themeStore.isMonochrome ? themeStore.monoDark : language.color
    }

    private var textColor: Color {
        if isBlocked { return .gray }
        if isSelected { return resolvedColor }
        return themeStore.mainText
    }

    var body: some View {
        Button(action: {
            if !isBlocked {
                onTap()
            }
        }) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 42))

                Text(language.name)
                    .font(themeStore.medium(14))
                    .foregroundColor(textColor)
            }
            .frame(height: 110)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        isSelected
                        ? resolvedColor.opacity(0.15)
                        : isBlocked
                        ? Color.gray.opacity(0.08)
                        : themeStore.cardBg
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(isSelected ? resolvedColor : themeStore.dividerColor, lineWidth: isSelected ? 2.5 : 1)
                    )
            )

            .scaleEffect(internalPressedState ? 0.96 : (isSelected ? 1.05 : 1.0))
            .opacity(isBlocked ? 0.5 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isBlocked)
        .pressAction { pressed in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
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
