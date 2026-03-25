import SwiftUI

struct LoadingStagesView: View {
    private let stages = [
        "Translating...",
        "Adding examples...",
        "Almost done..."
    ]

    @State private var currentStage = 0
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 4)

            Text(stages[currentStage])
                .font(.custom("Poppins-Bold", size: 15))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: currentStage)
        }
        .onAppear {
            Haptics.selection()
            advanceStages()
        }
    }

    private func advanceStages() {
        withAnimation { progress = 0.15 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { progress = 0.4 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            currentStage = min(1, stages.count - 1)
            withAnimation { progress = 0.55 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { progress = 0.75 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            currentStage = min(2, stages.count - 1)
            withAnimation { progress = 0.9 }
        }
    }
}
