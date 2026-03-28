import SwiftUI

struct StatusBannerView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(themeStore.bold(16))
                    .foregroundColor(themeStore.mainText)
                Text(subtitle)
                    .font(themeStore.regular(13))
                    .foregroundColor(themeStore.secondaryText)
            }

            Spacer()
        }
    }
}
