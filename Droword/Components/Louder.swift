import SwiftUI

struct Loader: View {
    @State private var phase: CGFloat = 0
    private let dotCount = 3
    private let dotSize: CGFloat = 10
    private let spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<dotCount, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(scale(for: i))
                    .opacity(Double(scale(for: i)))
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
            ) {
                phase = .pi * 2
            }
        }
    }

    private func scale(for index: Int) -> CGFloat {
        let offset = CGFloat(index) * 0.6
        return 0.6 + 0.4 * sin(phase + offset)
    }
}
