import SwiftUI

struct PracticeIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: size * 0.025) {
                VStack(spacing: size * 0.012) {
                    Text("3 / 10")
                        .font(.custom("Poppins-Medium", size: size * 0.035))
                        .foregroundColor(themeStore.secondaryText)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.15))
                            Capsule()
                                .fill(accent)
                                .frame(width: geo.size.width * 0.3)
                        }
                    }
                    .frame(height: size * 0.012)
                    .clipShape(Capsule())
                    .padding(.horizontal, size * 0.02)
                }

                Text("Ephemeral")
                    .font(.custom("Poppins-Bold", size: size * 0.07))
                    .foregroundColor(themeStore.mainText)

                Text("Choose the correct translation")
                    .font(.custom("Poppins-Regular", size: size * 0.03))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))

                Spacer().frame(height: size * 0.005)

                VStack(spacing: size * 0.02) {
                    quizOption(text: "Постоянный", isCorrect: false, isSelected: false, size: size)
                    quizOption(text: "Мимолётный", isCorrect: true, isSelected: true, size: size)
                    quizOption(text: "Огромный", isCorrect: false, isSelected: false, size: size)
                    quizOption(text: "Внезапный", isCorrect: false, isSelected: false, size: size)
                }
            }
            .padding(size * 0.045)
            .frame(width: size * 0.72)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.cardBg)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            )
            .offset(x: px * 0.25, y: py * 0.18)
        }
    }

    private func quizOption(text: String, isCorrect: Bool, isSelected: Bool, size: CGFloat) -> some View {
        HStack {
            Text(text)
                .font(.custom("Poppins-Medium", size: size * 0.037))
                .foregroundColor(isSelected ? darkerShade(of: accent, by: 0.4) : themeStore.mainText.opacity(0.7))
            Spacer()
            if isSelected && isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.04))
                    .foregroundColor(darkerShade(of: accent, by: 0.3))
            }
        }
        .padding(.vertical, size * 0.025)
        .padding(.horizontal, size * 0.035)
        .background(
            RoundedRectangle(cornerRadius: size * 0.035, style: .continuous)
                .fill(isSelected ? accent.opacity(0.3) : themeStore.secondaryText.opacity(0.08))
        )
    }
}
