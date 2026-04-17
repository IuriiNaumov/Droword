import SwiftUI

struct Duo3DStyle: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    let bgColor: Color
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .font(themeStore.bold(17))
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if themeStore.isDuolingo && !isDisabled {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(darkerShade(of: bgColor, by: 0.18))
                            .offset(y: 4)

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(bgColor)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isDisabled ? themeStore.secondaryText.opacity(0.4) : bgColor)
                    }
                }
            )
    }
}

struct Duo3DButtonStyle: ButtonStyle {
    var isDuolingo: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: isDuolingo && configuration.isPressed ? 4 : 0)
            .scaleEffect(isDuolingo ? 1.0 : (configuration.isPressed ? 0.97 : 1.0))
            .opacity(configuration.isPressed ? (isDuolingo ? 0.95 : 0.85) : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func duo3DStyle(_ color: Color, isDisabled: Bool = false) -> some View {
        modifier(Duo3DStyle(bgColor: color, isDisabled: isDisabled))
    }
}
