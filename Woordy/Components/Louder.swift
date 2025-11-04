import SwiftUI

struct Loader: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .scaleEffect(scale(for: i))
                    .opacity(Double(scale(for: i)))
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .onAppear { phase += 1 }
    }

    private func scale(for index: Int) -> CGFloat {
        return 0.6 + 0.4 * sin(phase + CGFloat(index) * 1.3)
    }
}
