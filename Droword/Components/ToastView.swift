import SwiftUI

enum AppToastType {
    case success
    case error
    case info
    case dark

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .dark: return "checkmark.circle.fill"
        }
    }

    var text: String {
        switch self {
        case .success:
            return String(localized: "Saved.")
        case .error:
            return String(localized: "Oops! Something went wrong.")
        case .info, .dark:
            return ""
        }
    }

    func tint(_ theme: ThemeStore) -> Color {
        switch self {
        case .success: return theme.accentGreen
        case .error: return theme.accentRed
        case .info: return theme.mainAccentColor
        case .dark: return .white
        }
    }

    var isDark: Bool { self == .dark }
}

struct AppToastChrome: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let text: String
    let tint: Color
    var inset: Bool = true
    var compact: Bool = false
    var dark: Bool = false

    private var darkBackground: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var darkForeground: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: compact ? 6 : 8) {
                Image(systemName: icon)
                    .font(.system(size: compact ? 13 : 15, weight: .bold))
                    .foregroundStyle(dark ? darkForeground : tint)
                    .symbolRenderingMode(.hierarchical)

                Text(text)
                    .font(compact ? themeStore.bold(13) : themeStore.bold(14))
                    .foregroundStyle(dark ? darkForeground : themeStore.mainText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(compact ? 1 : 2)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, compact ? 14 : 16)
            .padding(.vertical, compact ? 8 : 11)
            .frame(maxWidth: compact ? nil : 320, alignment: .leading)
            .background(
                Capsule(style: .continuous)
                    .fill(dark
                          ? darkBackground
                          : (themeStore.isGlass ? Color.clear : tint.opacity(compact ? 0.22 : 0.18)))
            )
            .modifier(GlassCardModifier(
                isGlass: !dark && themeStore.isGlass,
                cornerRadius: compact ? 18 : 22
            ))

            Spacer(minLength: 0)
        }
        .padding(.top, inset && !compact ? 12 : 0)
        .padding(.bottom, inset && compact ? 8 : 0)
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
    var fromEdge: Edge = .top
    var compact: Bool = false

    @State private var isVisible = false

    var body: some View {
        Group {
            if isVisible {
                AppToastChrome(
                    icon: icon ?? type.icon,
                    text: message ?? type.text,
                    tint: type.tint(themeStore),
                    compact: compact,
                    dark: type.isDark
                )
                .transition(.move(edge: fromEdge).combined(with: .opacity))
            }
        }
        .animation(DesignMotion.toast, value: isVisible)
        .onAppear {
            withAnimation(DesignMotion.toast) {
                isVisible = true
            }
            guard duration > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(DesignMotion.toast) {
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
            BannerToastView(type: .dark, message: "Copied", icon: "doc.on.doc", duration: 60)
            Spacer()
        }
        .padding(.top, 40)
    }
    .environmentObject(ThemeStore())
    .preferredColorScheme(.light)
}
