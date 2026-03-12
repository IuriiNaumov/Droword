import SwiftUI

enum AppToastType {
    case success
    case error

    var background: Color {
        return Color.accentBlack
    }

    var textColor: Color {
        switch self {
        case .success:
            return darkerShade(of: Color.accentBlue, by: 0.4)
        case .error:
            return darkerShade(of: Color.accentBlue, by: 0.4)
        }
    }

    var text: String {
        switch self {
        case .success:
            return "Saved."
        case .error:
            return "Oops! Something went wrong."
        }
    }
}

struct BannerToastView: View {

    let type: AppToastType
    let message: String?
    var duration: Double = 2.5

    @State private var isVisible = false

    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 10) {

                    Image(systemName: type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))

                    Text(message ?? type.text)
                        .font(.custom("Poppins-Medium", size: 15))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(type.background)
                )
                .padding(.top, 20)
                .transition(
                    .move(edge: .top)
                    .combined(with: .opacity)
                )
            }

            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isVisible = false
            }
        }
    }
}

#Preview("Light - Success & Error") {
    ZStack(alignment: .top) {
        Color("#FFF8E7")
            .ignoresSafeArea()

        VStack(spacing: 30) {
            Text("Light Mode")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(Color.mainBlack)
                .padding(.top, 40)

            BannerToastView(type: .success, message: nil, duration: 60)
            BannerToastView(type: .error, message: nil, duration: 60)

            Spacer()
        }
        .padding(.horizontal)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark - Success & Error") {
    ZStack(alignment: .top) {
        Color.black
            .ignoresSafeArea()

        VStack(spacing: 30) {
            Text("Dark Mode")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.white)
                .padding(.top, 40)

            BannerToastView(type: .success, message: nil, duration: 60)
            BannerToastView(type: .error, message: nil, duration: 60)

            Spacer()
        }
        .padding(.horizontal)
    }
    .preferredColorScheme(.dark)
}
