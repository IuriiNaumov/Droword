import SwiftUI

struct CustomizeIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        let cardWidth = size * 0.6
        let cardHeight = size * 0.42

        ZStack {
            // Tilted card
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(themeStore.cardBg)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        // Kanji
                        Text("茶")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(themeStore.mainAccentColor)

                        Spacer()

                        // Theme color dots (more spaced)
                        HStack(spacing: 10) {
                            Circle()
                                .fill(themeStore.mainAccentColor)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(themeStore.mainAccentColor, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                )

                            Circle()
                                .fill(themeStore.accentGreen)
                                .frame(width: 14, height: 14)

                            Circle()
                                .fill(Color.gray)
                                .frame(width: 14, height: 14)
                        }
                        .padding(.top, 4)
                    }

                    // Placeholder lines
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(themeStore.dividerColor.opacity(0.5))
                        .frame(width: cardWidth * 0.45, height: 5)
                        .padding(.top, 6)

                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(themeStore.dividerColor.opacity(0.35))
                        .frame(width: cardWidth * 0.3, height: 5)
                        .padding(.top, 6)

                    Spacer()

                    // Translation
                    Text("tea")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(themeStore.secondaryText)
                }
                .padding(14)
            }
            .frame(width: cardWidth, height: cardHeight)
            .rotationEffect(.degrees(-4))
            .offset(x: -size * 0.06 + px * 0.15, y: size * 0.04 + py * 0.1)

            // Magic wand + sparkle group
            ZStack {
                // Wand (handle directly under sparkle)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(red: 0.83, green: 0.66, blue: 0.42))
                    .frame(width: 7, height: 44)
                    .offset(y: 18)

                // Wand tip
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(themeStore.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .stroke(themeStore.dividerColor, lineWidth: 0.5)
                    )
                    .frame(width: 7, height: 14)
                    .offset(y: -5)

                // Main sparkle star
                Image(systemName: "sparkle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(red: 0.96, green: 0.82, blue: 0.13))
                    .offset(y: -18)
            }
            .rotationEffect(.degrees(-45))
            .offset(x: size * 0.22 + px * 0.08, y: -size * 0.2 + py * 0.06)

            // Scattered color sparkles
            // Purple
            Circle()
                .fill(themeStore.mainAccentColor)
                .frame(width: 9, height: 9)
                .offset(x: size * 0.32, y: -size * 0.32)

            Circle()
                .fill(themeStore.mainAccentColor.opacity(0.6))
                .frame(width: 6, height: 6)
                .offset(x: size * 0.38, y: -size * 0.22)

            // Green
            Circle()
                .fill(themeStore.accentGreen)
                .frame(width: 7, height: 7)
                .offset(x: size * 0.14, y: -size * 0.36)

            Circle()
                .fill(themeStore.accentGreen.opacity(0.6))
                .frame(width: 5, height: 5)
                .offset(x: size * 0.06, y: -size * 0.28)

            // Gray
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 5, height: 5)
                .offset(x: size * 0.4, y: -size * 0.3)

            // Sparkle lines
            SparkLine()
                .stroke(Color(red: 0.96, green: 0.82, blue: 0.13).opacity(0.5), lineWidth: 1.5)
                .frame(width: 10, height: 10)
                .offset(x: size * 0.28, y: -size * 0.34)

            SparkLine()
                .stroke(Color(red: 0.96, green: 0.82, blue: 0.13).opacity(0.5), lineWidth: 1.5)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(90))
                .offset(x: size * 0.1, y: -size * 0.32)

            // Bottom label pill
            Text("Change the look anytime")
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundStyle(themeStore.mainText.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(themeStore.mainText.opacity(0.06))
                )
                .offset(y: size * 0.38 + py * 0.04)
        }
        .allowsHitTesting(false)
    }
}

private struct SparkLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}
