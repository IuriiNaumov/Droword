import SwiftUI

struct QuizMultipleChoiceExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let isReversed: Bool
    let options: [String]
    let selectedOption: String?
    let shakeOffset: CGFloat

    var onSelect: (String) -> Void

    private var prompt: String {
        isReversed ? item.translation : item.word
    }

    private var correctAnswer: String {
        isReversed ? item.word : item.translation
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(prompt)
                    .font(themeStore.bold(28))
                    .foregroundColor(themeStore.mainText)
                    .multilineTextAlignment(.center)

                if !isReversed, let tr = item.transcription, !tr.isEmpty {
                    Text("[\(tr)]")
                        .font(themeStore.regular(14))
                        .foregroundColor(themeStore.secondaryText)
                }

                Text(isReversed ? "Choose the correct word" : "Choose the correct translation")
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    optionButton(option: option)
                }
            }
            .padding(.horizontal, 24)
            .offset(x: hasAnswered && !isCorrect ? shakeOffset : 0)

            Spacer()
        }
    }

    private func optionButton(option: String) -> some View {
        let isThisCorrect = option.lowercased() == correctAnswer.lowercased()
        let isSelected = selectedOption == option
        let isIrrelevant = hasAnswered && !isThisCorrect && !isSelected

        var bgColor: Color {
            if !hasAnswered { return themeStore.cardBg }
            if isThisCorrect { return themeStore.accentGreen }
            if isSelected && !isThisCorrect { return themeStore.accentRed }
            return themeStore.cardBg
        }

        var textColor: Color {
            if !hasAnswered { return themeStore.mainText }
            if isThisCorrect { return themeStore.mainText }
            if isSelected && !isThisCorrect { return themeStore.mainText }
            return themeStore.mainText.opacity(0.4)
        }

        return Button {
            onSelect(option)
        } label: {
            HStack {
                Text(option)
                    .font(themeStore.medium(16))
                    .foregroundColor(textColor)

                Spacer()

                if hasAnswered && isThisCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeStore.mainText)
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeStore.mainText)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(bgColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
        .opacity(isIrrelevant ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: hasAnswered)
        .accessibilityLabel(Text(option))
        .accessibilityAddTraits(hasAnswered && isThisCorrect ? .isSelected : [])
    }
}
