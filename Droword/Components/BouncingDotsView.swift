import SwiftUI

struct BouncingDotsView: View {
    @State private var phase: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                    .offset(y: dotOffset(for: index))
            }
        }
        .frame(height: 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                phase.toggle()
            }
        }
    }

    private func dotOffset(for index: Int) -> CGFloat {
        let up = index.isMultiple(of: 2)
        let offset: CGFloat = 5
        if up {
            return phase ? -offset : offset
        } else {
            return phase ? offset : -offset
        }
    }
}
