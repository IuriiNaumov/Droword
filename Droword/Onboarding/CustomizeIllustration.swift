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
            VStack(spacing: size * 0.025) {
                VStack(spacing: size * 0.012) {
                    Circle()
                        .fill(themeStore.secondaryText.opacity(0.15))
                        .frame(width: size * 0.1, height: size * 0.1)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.045, weight: .medium))
                                .foregroundColor(themeStore.mainText.opacity(0.5))
                        )

                    Text("User")
                        .font(.custom("Poppins-Bold", size: size * 0.038))
                        .foregroundColor(themeStore.mainText)
                }

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: size * 0.014) {
                        Text("Theme")
                            .font(.custom("Poppins-Medium", size: size * 0.034))
                            .foregroundColor(themeStore.mainText)

                        HStack(spacing: size * 0.02) {
                            ForEach(0..<5, id: \.self) { i in
                                Circle()
                                    .fill(palette[i])
                                    .frame(width: size * 0.05, height: size * 0.05)
                                    .overlay(
                                        Circle()
                                            .stroke(i == 1 ? themeStore.mainText : Color.clear, lineWidth: 1.5)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, size * 0.022)
                    .padding(.horizontal, size * 0.03)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeStore.cardBg)
                )

                VStack(spacing: 0) {
                    settingsRow(icon: "moon.fill", color: accent, title: "Appearance", value: "Light", size: size)
                    settingsRow(icon: "textformat.size", color: themeStore.accentGreen, title: "Language", value: "English", size: size)
                    settingsRow(icon: "bell.badge.fill", color: themeStore.accentPink, title: "Notifications", value: nil, size: size)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: size * 0.01) {
                    HStack {
                        Text("12 words")
                            .font(.custom("Poppins-Bold", size: size * 0.033))
                            .foregroundColor(themeStore.mainText)
                        Spacer()
                        Text("3 day streak")
                            .font(.custom("Poppins-Medium", size: size * 0.028))
                            .foregroundColor(themeStore.secondaryText)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.15))
                            Capsule()
                                .fill(accent)
                                .frame(width: geo.size.width * 0.65)
                        }
                    }
                    .frame(height: size * 0.016)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, size * 0.01)
            }
            .padding(size * 0.035)
            .frame(width: size * 0.72)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.appBg)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            )
            .offset(x: px * 0.25, y: py * 0.18)
        }
    }

    private func settingsRow(icon: String, color: Color, title: String, value: String?, size: CGFloat) -> some View {
        HStack(spacing: size * 0.022) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: size * 0.045, height: size * 0.045)
                Image(systemName: icon)
                    .font(.system(size: size * 0.022, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.custom("Poppins-Regular", size: size * 0.033))
                .foregroundColor(themeStore.mainText)

            Spacer()

            if let value {
                Text(value)
                    .font(.custom("Poppins-Regular", size: size * 0.028))
                    .foregroundColor(themeStore.secondaryText)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: size * 0.022, weight: .semibold))
                .foregroundColor(themeStore.secondaryText.opacity(0.5))
        }
        .padding(.vertical, size * 0.018)
        .padding(.horizontal, size * 0.025)
        .background(themeStore.cardBg)
    }
}
