import SwiftUI

struct LoadingStagesView: View {
    @State private var phase: CGFloat = 0
    @State private var isActive = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                let offset: CGFloat = index % 2 == 0
                    ? -6 * sin(phase)
                    : 6 * sin(phase)
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(y: offset)
            }
        }
        .onAppear {
            isActive = true
            startBounce()
        }
        .onDisappear {
            isActive = false
        }
    }

    private func startBounce() {
        guard isActive else { return }

        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .pi
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard isActive else { return }
            Haptics.lightImpact()
            withAnimation(.easeInOut(duration: 0.4)) {
                phase = 2 * .pi
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard isActive else { return }
                Haptics.lightImpact()
                phase = 0
                startBounce()
            }
        }
    }
}
