import SwiftUI

struct QuizTypingExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let isAlmostCorrect: Bool
    let isReversed: Bool
    let shakeOffset: CGFloat
    let hintShown: Bool
    let hintText: String

    @Binding var typingInput: String
    var isInputFocused: FocusState<Bool>.Binding

    var onSubmit: () -> Void

    private var prompt: String {
        isReversed ? item.translation : item.word
    }

    private var expected: String {
        isReversed ? item.word : item.translation
    }

    private var fieldBackground: Color {
        if !hasAnswered { return themeStore.cardBg }
        if isAlmostCorrect { return themeStore.accentGold.opacity(0.08) }
        if isCorrect { return themeStore.accentGreen.opacity(0.08) }
        return themeStore.accentRed.opacity(0.08)
    }

    private var borderColor: Color {
        if !hasAnswered {
            return isInputFocused.wrappedValue ? themeStore.mainText : themeStore.dividerColor
        }
        if isAlmostCorrect { return themeStore.accentGold }
        return isCorrect ? themeStore.accentGreen : themeStore.accentRed
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(prompt)
                    .font(themeStore.bold(28))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.center)

                if !isReversed, let tr = item.transcription, !tr.isEmpty {
                    Text("[\(tr)]")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                }

                Text(isReversed ? "Type the word" : "Type the translation")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                TextField("Your answer", text: $typingInput)
                    .focused(isInputFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(themeStore.regular(16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(fieldBackground)
                    .foregroundStyle(themeStore.mainText)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor, lineWidth: hasAnswered ? 2.5 : 1.5)
                    )
                    .cornerRadius(14)
                    .disabled(hasAnswered)
                    .submitLabel(.done)
                    .onSubmit {
                        if !hasAnswered && !typingInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            onSubmit()
                        }
                    }
                    .offset(x: shakeOffset)

                feedback
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var feedback: some View {
        Group {
            if !hasAnswered && hintShown {
                QuizFeedbackBadge(
                    icon: "lightbulb.fill",
                    text: String(localized: "Hint: \(hintText)"),
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: String(localized: "Almost!"),
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && !isCorrect && !isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "xmark.circle.fill",
                    text: String(localized: "Correct: \(expected)"),
                    color: themeStore.accentRed
                )
            }

            if hasAnswered && isCorrect && !isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: String(localized: "Correct!"),
                    color: themeStore.accentGreen
                )
            }
        }
    }
}
