import SwiftUI

struct DictionaryIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent.opacity(0.15))
                .frame(width: size * 0.68, height: size * 0.52)
                .rotationEffect(.degrees(-3))
                .offset(x: -size * 0.02 + px * 0.12, y: size * 0.02 + py * 0.08)

            VStack(alignment: .leading, spacing: 0) {
                Text("Travel")
                    .font(.custom("Poppins-Medium", size: size * 0.04))
                    .foregroundColor(darkerShade(of: accent, by: 0.45))
                    .padding(.vertical, size * 0.014)
                    .padding(.horizontal, size * 0.03)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accent.opacity(0.32))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(darkerShade(of: accent, by: 0.15), lineWidth: 1)
                    )

                Spacer().frame(height: size * 0.025)

                HStack(alignment: .top, spacing: size * 0.015) {
                    Text("Serendipity")
                        .font(.custom("Poppins-Bold", size: size * 0.065))
                        .foregroundColor(themeStore.mainText)

                    Spacer()

                    Image(systemName: "waveform")
                        .font(.system(size: size * 0.032, weight: .medium))
                        .foregroundColor(themeStore.mainText.opacity(0.4))
                        .padding(.top, size * 0.015)
                }

                Text("/ˌser.ənˈdɪp.ə.ti/")
                    .font(.custom("Poppins-Regular", size: size * 0.035))
                    .foregroundColor(themeStore.secondaryText)

                Spacer().frame(height: size * 0.02)

                Text("Счастливая случайность")
                    .font(.custom("Poppins-Regular", size: size * 0.038))
                    .foregroundColor(themeStore.mainText.opacity(0.8))

                Spacer().frame(height: size * 0.02)

                HStack(spacing: 0) {
                    Text("A ")
                        .font(.custom("Poppins-Regular", size: size * 0.032))
                        .foregroundColor(themeStore.mainText.opacity(0.6))
                    Text("serendipity")
                        .font(.custom("Poppins-Bold", size: size * 0.032))
                        .foregroundColor(.orange)
                    Text(" led me...")
                        .font(.custom("Poppins-Regular", size: size * 0.032))
                        .foregroundColor(themeStore.mainText.opacity(0.6))
                }
            }
            .padding(size * 0.05)
            .frame(width: size * 0.68, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(accent.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(themeStore.secondaryText.opacity(0.12), lineWidth: 1)
            )
            .offset(x: px * 0.3, y: py * 0.2)
        }
    }
}
