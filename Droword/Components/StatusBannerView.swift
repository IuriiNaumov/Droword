import SwiftUI

struct StatusBannerView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeStore.iconCircleFill(colorScheme: colorScheme))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

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
