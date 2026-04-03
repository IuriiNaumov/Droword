import SwiftUI

struct DictionaryIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        let cardWidth = size * 0.65
        let cardHeight = size * 0.56
        let cornerRadius: CGFloat = 20

        ZStack {
            // Card shadow (back-most)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(themeStore.mainText.opacity(0.08))
                .frame(width: cardWidth, height: cardHeight)
                .offset(x: 6 + px * 0.06, y: 10 + py * 0.04)

            // Card back
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(themeStore.mainText.opacity(0.05))
                .frame(width: cardWidth, height: cardHeight)
                .offset(x: 3 + px * 0.08, y: 5 + py * 0.05)

            // Main card
            VStack(alignment: .leading, spacing: 0) {
                // Category tag
                Text("Anime")
                    .font(.custom("Poppins-SemiBold", size: 10))
                    .foregroundColor(themeStore.accentPurple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(themeStore.accentPurple.opacity(0.18))
                    )
                    .padding(.bottom, 8)

                // Big kanji
                Text("茶")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(themeStore.mainText)
                    .padding(.bottom, 2)

                // Phonetic
                Text("/otʃa/")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(themeStore.secondaryText)
                    .padding(.bottom, 8)

                // Divider
                Rectangle()
                    .fill(themeStore.dividerColor)
                    .frame(height: 1)
                    .padding(.bottom, 8)

                // Translation
                Text("tea")
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundColor(themeStore.mainText)
                    .padding(.bottom, 6)

                Text("Noun")
                    .font(.custom("Poppins-SemiBold", size: 9))
                    .foregroundColor(themeStore.accentGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(themeStore.accentGreen.opacity(0.18))
                    )
            }
            .padding(16)
            .frame(width: cardWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(themeStore.cardBg)
            )
            .offset(x: px * 0.12, y: py * 0.08)

        }
        .allowsHitTesting(false)
    }
}
