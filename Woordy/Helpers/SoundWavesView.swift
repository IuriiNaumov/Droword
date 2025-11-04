import SwiftUI

struct SoundWavesView: View {
    @State private var barHeights: [CGFloat] = [8, 12, 8]
    let isPlaying: Bool

    private let barWidth: CGFloat = 4
    private let maxHeight: CGFloat = 20
    private let minHeight: CGFloat = 6

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(Color.black)
                    .frame(width: barWidth, height: barHeights[index])
                    .cornerRadius(2)
            }
        }
        .onAppear { if isPlaying { startAnimation() } }
        .onChange(of: isPlaying) { animating in
            if animating {
                startAnimation()
            } else {
                resetBars()
            }
        }
    }

    private func startAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            barHeights = barHeights.map { _ in CGFloat.random(in: minHeight...maxHeight) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if isPlaying {
                startAnimation()
            }
        }
    }

    private func resetBars() {
        withAnimation { barHeights = [8, 12, 8] }
    }
}
