import SwiftUI

struct StatusBannerView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    var iconColor: Color? = nil
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var useCard: Bool = false

    var body: some View {
        content
            .modifier(OptionalCardChrome(enabled: useCard, themeStore: themeStore))
    }

    private var content: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(iconColor ?? themeStore.mainText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(themeStore.bold(16))
                    .foregroundStyle(themeStore.mainText)
                Text(subtitle)
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct OptionalCardChrome: ViewModifier {
    let enabled: Bool
    let themeStore: ThemeStore

    func body(content: Content) -> some View {
        if enabled {
            content
                .padding(16)
                .cleanCard(themeStore: themeStore, cornerRadius: DesignRadius.large)
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBannerView(
            icon: "wifi.slash",
            iconColor: .orange,
            title: "You're offline",
            subtitle: "AI features need a connection.",
            useCard: true
        )
        StatusBannerView(
            icon: "clock",
            title: "Daily limit reached",
            subtitle: "Come back tomorrow."
        )
    }
    .padding()
    .environmentObject(ThemeStore())
}
