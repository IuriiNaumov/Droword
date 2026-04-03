import SwiftUI

struct CustomizeIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    private var palette: [Color] {[
        themeStore.accentBlue,
        themeStore.accentGreen,
        themeStore.accentPurple,
        themeStore.accentGold,
        themeStore.accentPink
    ]}

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Circle()
                        .fill(themeStore.secondaryText.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(themeStore.mainText.opacity(0.7))
                        )

                    Text("User")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(themeStore.mainText)

                    Text("1 day with Droword")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(themeStore.secondaryText)
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    settingsRow(
                        icon: "moon.fill",
                        color: themeStore.monoDark,
                        title: "Appearance",
                        value: "Light"
                    )
                    settingsRow(
                        icon: "textformat.size",
                        color: themeStore.iconGreen,
                        title: "Language Pair",
                        value: "English"
                    )
                    settingsRow(
                        icon: "bell.badge.fill",
                        color: themeStore.iconPink,
                        title: "Notifications",
                        value: nil
                    )
                    settingsRow(
                        icon: "mic.fill",
                        color: themeStore.iconBlue,
                        title: "Voice & Speech",
                        value: nil
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(20)
            .frame(width: size * 0.78)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.appBg)

            )
            .offset(x: px * 0.25, y: py * 0.18)
        }
        .allowsHitTesting(false)
    }

    private func settingsRow(icon: String, color: Color, title: String, value: String?) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(themeStore.mainText)

            Spacer()

            if let value {
                Text(value)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeStore.secondaryText.opacity(0.6))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(themeStore.cardBg)
    }
}
