import SwiftUI

struct StatusBannerView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    var iconColor: Color? = nil
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
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

            Spacer()
        }
    }
}
