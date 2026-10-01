import SwiftUI
import UIKit

struct LanguageCube: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let language: LanguageOption
    let isSelected: Bool
    let isBlocked: Bool
    let onTap: () -> Void

    private var accent: Color { themeStore.mainAccentColor }

    var body: some View {
        Button {
            guard !isBlocked else { return }
            onTap()
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    LanguageFlagView(language: language.name, width: 38, height: 26)

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
                    RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                        .fill(
                            isSelected
                                ? accent.opacity(0.14)
                                : (themeStore.isGlass ? Color.clear : themeStore.cardBg)
                        )
                )
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isSelected, cornerRadius: themeStore.cardRadius, interactive: false))
            }
            .opacity(isBlocked ? 0.4 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isSelected)
        }
        .buttonStyle(LanguageCubePressStyle())
        .disabled(isBlocked)
        .accessibilityLabel(Text(language.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct LanguageCubePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
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
