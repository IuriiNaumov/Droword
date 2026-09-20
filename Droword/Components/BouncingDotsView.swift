import SwiftUI

struct BouncingDotsView: View {
    private let period: Double = 0.9

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let wave = sin(t * 2 * .pi / period)

            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                        .offset(y: dotOffset(for: index, wave: wave))
                }
            }
            .frame(height: 20)
        }
    }

    private func dotOffset(for index: Int, wave: Double) -> CGFloat {
        let up = index.isMultiple(of: 2)
        let offset: CGFloat = 5
        let signed = CGFloat(wave) * offset
        return up ? -signed : signed
    }
}

#Preview {
    BouncingDotsView()
        .padding()
        .background(Color.blue)
}
