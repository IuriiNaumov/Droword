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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(prompt.displayCapitalized)
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
                FormTextField(
                    title: String(localized: "Your answer"),
                    text: $typingInput,
                    status: fieldStatus,
                    isDisabled: hasAnswered,
                    autocapitalization: .never,
                    disableAutocorrection: true,
                    onSubmit: {
                        if !hasAnswered && !typingInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            onSubmit()
                        }
                    },
                    externalFocus: isInputFocused
                )
                .offset(x: shakeOffset)

                feedback
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var fieldStatus: FormTextFieldStatus {
        guard hasAnswered else { return .normal }
        if isAlmostCorrect { return .almost }
        return isCorrect ? .correct : .wrong
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
                    text: DuoChaosCopy.almost(),
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && !isCorrect && !isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "xmark.circle.fill",
                    text: DuoChaosCopy.wrongReveal(expected),
                    color: themeStore.accentRed
                )
            }

            if hasAnswered && isCorrect && !isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: DuoChaosCopy.correct(),
                    color: themeStore.accentGreen
                )
            }
        }
    }
}

private struct QuizTypingExercisePreview: View {
    @State private var typingInput = ""
    @FocusState private var focused: Bool

    var body: some View {
        QuizTypingExercise(
            item: QuizSessionManager.QuizItem(
        id: UUID(),
        word: "hola",
        translation: "hello",
        transcription: "ˈola",
        tag: "basics",
        example: "¡Hola!"
    ),
            hasAnswered: false,
            isCorrect: false,
            isAlmostCorrect: false,
            isReversed: false,
            shakeOffset: 0,
            hintShown: false,
            hintText: "",
            typingInput: $typingInput,
            isInputFocused: $focused,
            onSubmit: {}
        )
        .environmentObject(ThemeStore())
    }
}

#Preview {
    QuizTypingExercisePreview()
}
