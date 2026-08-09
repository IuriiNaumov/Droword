import SwiftUI

struct PracticeIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        let cardWidth = size * 0.78

        ZStack {
            VStack(spacing: 0) {
                // Progress header
                VStack(spacing: 6) {
                    HStack {
                        Text("2/7")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundStyle(themeStore.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(themeStore.dividerColor.opacity(0.5))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(accent)
                                .frame(width: geo.size.width * 0.33, height: 6)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 14)

                Spacer()

                // Word and instruction
                VStack(spacing: 6) {
                    Text("tea")
                        .font(.custom("Poppins-Bold", size: 26))
                        .foregroundStyle(themeStore.mainText)

                    Text("Type the word")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(themeStore.secondaryText)
                }

                Spacer()

                // Input field
                HStack(spacing: 0) {
                    Text("お茶")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(themeStore.mainText)

                    // Cursor
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(accent)
                        .frame(width: 2, height: 20)
                        .padding(.leading, 2)

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(themeStore.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(accent, lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 20)

                // Hint pill
                HStack(spacing: 6) {
                    Text("💡")
                        .font(.system(size: 10))
                    Text("Hint: お..., 2 letters")
                        .font(.custom("Poppins-Medium", size: 11))
                        .foregroundStyle(themeStore.mainText.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(themeStore.accentGold.opacity(0.18))
                )
                .padding(.top, 10)

                Spacer()

                // Check button
                Text("Check")
                    .font(.custom("Poppins-Bold", size: 15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accent)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            .frame(width: cardWidth)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.appBg)
            )
            .offset(x: px * 0.25, y: py * 0.18)
        }
        .allowsHitTesting(false)
    }
}
