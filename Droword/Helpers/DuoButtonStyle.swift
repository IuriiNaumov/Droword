import SwiftUI

struct Duo3DStyle: ViewModifier {
    let bgColor: Color
    var isDisabled: Bool = false
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .font(.custom("Poppins-Bold", size: 17))
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(darkerShade(of: bgColor, by: 0.15))
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(isDisabled ? Color.mainGrey.opacity(0.5) : bgColor)
                        .padding(.bottom, isPressed ? 1 : 4)
                }
            )
            .offset(y: isPressed ? 3 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .animation(.spring(response: 0.15, dampingFraction: 0.9), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isDisabled { isPressed = true } }
                    .onEnded { _ in isPressed = false }
            )
            .allowsHitTesting(!isDisabled)
    }
}

extension View {
    func duo3DStyle(_ color: Color, isDisabled: Bool = false) -> some View {
        modifier(Duo3DStyle(bgColor: color, isDisabled: isDisabled))
    }
}
