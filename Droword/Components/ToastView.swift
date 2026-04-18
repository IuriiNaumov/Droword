import SwiftUI

enum AppToastType {
    case success
    case error

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    var text: String {
        switch self {
        case .success:
            return String(localized: "Saved.")
        case .error:
            return String(localized: "Oops! Something went wrong.")
        }
    }
}

struct BannerToastView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let type: AppToastType
    let message: String?
    var duration: Double = 2.5

    @State private var isVisible = false

    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 10) {

                    Image(systemName: type.icon)
                        .foregroundColor(themeStore.toastText)
                        .font(.system(size: 18, weight: .semibold))

                    Text(message ?? type.text)
                        .font(themeStore.medium(15))
                        .foregroundColor(themeStore.toastText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeStore.isGlass ? Color.clear : themeStore.toastBg)
                )
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
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
