import SwiftUI

struct SunView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 1.0, green: 0.847, blue: 0.302))
                    .frame(width: size * 0.2, height: size * 0.433)
                    .offset(y: -size * 0.27)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle()
                .fill(Color(red: 0.957, green: 0.639, blue: 0.0))
                .frame(width: size * 0.233, height: size * 0.233)
        }
        .frame(width: size, height: size)
    }
}
