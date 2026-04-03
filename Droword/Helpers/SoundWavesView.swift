import SwiftUI

struct SoundWavesView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var barHeights: [CGFloat] = [8, 12, 8]
    @State private var animating = false
    let isPlaying: Bool

    private let barWidth: CGFloat = 4
    private let maxHeight: CGFloat = 20
    private let minHeight: CGFloat = 6

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(themeStore.mainText)
                    .frame(width: barWidth, height: barHeights[index])
                    .cornerRadius(2)
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                animating = true
                tick()
            } else {
                animating = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    barHeights = [8, 12, 8]
                }
            }
        }
        .onAppear {
            if isPlaying {
                animating = true
                tick()
            }
        }
    }

    private func tick() {
        guard animating else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            barHeights = barHeights.map { _ in CGFloat.random(in: minHeight...maxHeight) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tick()
        }
    }
}
