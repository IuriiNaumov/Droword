import SwiftUI

enum AppToastType {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var text: String {
        switch self {
        case .success:
            return String(localized: "Saved.")
        case .error:
            return String(localized: "Oops! Something went wrong.")
        case .info:
            return ""
        }
    }

    func tint(_ theme: ThemeStore) -> Color {
        switch self {
        case .success: return theme.accentGreen
        case .error: return theme.accentRed
        case .info: return theme.mainAccentColor
        }
    }
}

/// Shared pill for overlay toasts and in-flow feedback.
struct AppToastChrome: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    let text: String
    let tint: Color
    var inset: Bool = true

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                    .symbolRenderingMode(.hierarchical)

                Text(text)
                    .font(themeStore.bold(14))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: 320, alignment: .leading)
            .background(
                Capsule(style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : tint.opacity(0.18))
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 22))

            Spacer(minLength: 0)
        }
        .padding(.top, inset ? 12 : 0)
        .padding(.horizontal, inset ? 16 : 0)
        .allowsHitTesting(false)
    }
}

struct BannerToastView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let type: AppToastType
    let message: String?
    var icon: String? = nil
    var duration: Double = 2.5

    @State private var isVisible = false

    var body: some View {
        Group {
            if isVisible {
                AppToastChrome(
                    icon: icon ?? type.icon,
                    text: message ?? type.text,
                    tint: type.tint(themeStore)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
            guard duration > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isVisible = false
                }
            }
        }
    }
}

#Preview("Light - Success & Error") {
    ZStack(alignment: .top) {
        Color("#FFF8E7")
            .ignoresSafeArea()

        VStack(spacing: 16) {
            BannerToastView(type: .success, message: nil, duration: 60)
            BannerToastView(type: .error, message: nil, duration: 60)
            BannerToastView(type: .info, message: "Pull to refresh", duration: 60)
            Spacer()
        }
        .padding(.top, 40)
    }
    .environmentObject(ThemeStore())
    .preferredColorScheme(.light)
}
