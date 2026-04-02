import SwiftUI

struct SakuraFlower: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 1.0, green: 0.56, blue: 0.82))
                    .frame(width: size * 0.233, height: size * 0.367)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(Color(red: 1.0, green: 0.37, blue: 0.69))
                .frame(width: size * 0.167, height: size * 0.167)
        }
        .frame(width: size, height: size)
    }
}
