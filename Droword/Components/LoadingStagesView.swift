import SwiftUI

struct LoadingStagesView: View {
    var dotSize: CGFloat = 8
    var bounceHeight: CGFloat = 6
    var spacing: CGFloat = 6
    var color: Color = .white

    @State private var animating = false
    @State private var isActive = false

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: animating ? (index % 2 == 0 ? -bounceHeight : bounceHeight) : 0)
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

        withAnimation(.easeInOut(duration: 0.35)) {
            animating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard isActive else { return }
            Haptics.lightImpact()
            withAnimation(.easeInOut(duration: 0.35)) {
                animating = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard isActive else { return }
                Haptics.lightImpact()
                startBounce()
            }
        }
    }
}
