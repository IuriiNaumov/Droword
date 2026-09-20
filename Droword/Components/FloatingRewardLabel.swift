import SwiftUI

struct FloatingRewardLabel: View {
    let text: String
    var color: Color

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.4

    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .scaleEffect(scale)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.95)) {
                    offsetY = -64
                }
                withAnimation(.easeIn(duration: 0.4).delay(0.55)) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    FloatingRewardLabel(text: "+10", color: .orange)
        .frame(width: 120, height: 120)
}
