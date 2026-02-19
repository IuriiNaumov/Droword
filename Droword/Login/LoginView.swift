import SwiftUI
import UIKit

struct LoginView: View {
    var body: some View {
        ZStack {
            Color.clear
            VStack(spacing: 0) {
                LoginFieldsView()
            }
        }
    }
}

#Preview {
    LoginView()
}

struct RoundedCorners: Shape {
    var radius: CGFloat = 16.0
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
