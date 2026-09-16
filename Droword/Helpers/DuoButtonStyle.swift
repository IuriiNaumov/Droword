import SwiftUI

struct Duo3DStyle: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    let bgColor: Color
    var isDisabled: Bool = false

    private var use3D: Bool { themeStore.isDuolingo && !themeStore.isGlass }

    func body(content: Content) -> some View {
        content
            .font(themeStore.bold(17))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if themeStore.isGlass {
                        RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                            .fill(isDisabled ? themeStore.secondaryText.opacity(0.4) : bgColor.opacity(0.6))
                    } else if isDisabled {
                        RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                            .fill(themeStore.secondaryText.opacity(0.4))
                    } else if use3D {
                        RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                            .fill(darkerShade(of: bgColor, by: 0.18))
                            .offset(y: 4)

                        RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                            .fill(bgColor)
                    } else {
                        RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                            .fill(bgColor)
                    }
                }
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isDisabled, cornerRadius: DesignRadius.large))
    }
}

struct Duo3DButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeStore: ThemeStore

    func makeBody(configuration: Configuration) -> some View {
        let use3D = themeStore.isDuolingo
        return configuration.label
            .offset(y: use3D && configuration.isPressed ? 4 : 0)
            .scaleEffect(use3D ? 1.0 : (configuration.isPressed ? 0.97 : 1.0))
            .opacity(configuration.isPressed ? (use3D ? 0.95 : 0.85) : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func duo3DStyle(_ color: Color, isDisabled: Bool = false) -> some View {
        modifier(Duo3DStyle(bgColor: color, isDisabled: isDisabled))
    }
}
