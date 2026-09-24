import SwiftUI

struct SoundWavesView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var barHeights: [CGFloat] = [8, 12, 8]
    @State private var tickTask: Task<Void, Never>?
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
            syncAnimation(playing: playing)
        }
        .onAppear {
            syncAnimation(playing: isPlaying)
        }
        .onDisappear {
            stopAnimation(reset: false)
        }
    }

    private func syncAnimation(playing: Bool) {
        if playing {
            startAnimation()
        } else {
            stopAnimation(reset: true)
        }
    }

    private func startAnimation() {
        tickTask?.cancel()
        tickTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.28)) {
                    barHeights = (0..<3).map { _ in CGFloat.random(in: minHeight...maxHeight) }
                }
                try? await Task.sleep(for: .milliseconds(280))
            }
        }
    }

    private func stopAnimation(reset: Bool) {
        tickTask?.cancel()
        tickTask = nil
        guard reset else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            barHeights = [8, 12, 8]
        }
    }
}

#Preview {
    SoundWavesView(isPlaying: true)
        .padding()
        .environmentObject(ThemeStore())
}
