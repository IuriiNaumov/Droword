import SwiftUI

struct PracticeIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Progress header — matches QuizMixedView progressHeader
                VStack(spacing: 6) {
                    HStack {
                        Text("3 / 10")
                            .font(.custom("Poppins-Medium", size: 13))
                            .foregroundColor(themeStore.secondaryText)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(themeStore.accentRed)
                            Text("3")
                                .font(.custom("Poppins-Bold", size: 14))
                                .foregroundColor(themeStore.accentRed)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Segmented progress bar — matches QuizMixedView segmentedProgressBar
                    HStack(spacing: 2) {
                        ForEach(0..<10, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(segmentColor(for: index))
                                .frame(height: 6)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 12)

                Spacer()

                // Word prompt — matches QuizMixedView multipleChoiceContent
                VStack(spacing: 8) {
                    Text("Ephemeral")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(themeStore.mainText)
                        .multilineTextAlignment(.center)

                    Text("/ɪˈfem.ər.əl/")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(themeStore.secondaryText)

                    Text("Choose the correct translation")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(themeStore.secondaryText.opacity(0.7))
                        .padding(.top, 8)
                }
                .padding(.bottom, 24)

                // Options — matches QuizMixedView mcOptionButton
                VStack(spacing: 12) {
                    optionRow(text: "Постоянный", state: .normal)
                    optionRow(text: "Мимолётный", state: .correct)
                    optionRow(text: "Огромный", state: .dimmed)
                    optionRow(text: "Внезапный", state: .dimmed)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .frame(width: size * 0.78)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.appBg)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            )
            .offset(x: px * 0.25, y: py * 0.18)
        }
        .allowsHitTesting(false)
    }

    private enum OptionState { case normal, correct, dimmed }

    private func optionRow(text: String, state: OptionState) -> some View {
        HStack {
            Text(text)
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(state == .dimmed ? themeStore.mainText.opacity(0.4) : themeStore.mainText)

            Spacer()

            if state == .correct {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeStore.mainText)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(state == .correct ? themeStore.accentGreen : themeStore.cardBg)
        )
        .opacity(state == .dimmed ? 0.4 : 1.0)
    }

    private func segmentColor(for index: Int) -> Color {
        if index < 2 {
            return themeStore.accentGreen       // answered correctly
        }
        if index == 2 {
            return themeStore.mainAccentColor.opacity(0.5)  // current
        }
        return themeStore.dividerColor.opacity(0.4)         // upcoming
    }
}
