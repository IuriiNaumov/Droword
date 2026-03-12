import SwiftUI

struct Duo3DStyle: ViewModifier {
    let bgColor: Color
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .font(.custom("Poppins-Bold", size: 17))
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isDisabled ? Color.mainGrey.opacity(0.4) : bgColor)
            )
    }
}

struct Duo3DButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func duo3DStyle(_ color: Color, isDisabled: Bool = false) -> some View {
        modifier(Duo3DStyle(bgColor: color, isDisabled: isDisabled))
    }
}
