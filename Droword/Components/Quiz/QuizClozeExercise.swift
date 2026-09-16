import SwiftUI

struct QuizClozeExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let isAlmostCorrect: Bool
    let clozeRevealed: Bool
    let shakeOffset: CGFloat
    let hintShown: Bool
    let hintText: String

    @Binding var typingInput: String
    var isInputFocused: FocusState<Bool>.Binding

    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("Fill in the blank")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))

                if let parts = clozeSentence {
                    clozeTextBlock(before: parts.before, after: parts.after)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                if !item.translation.isEmpty {
                    Text("(\(item.translation))")
                        .font(themeStore.medium(16))
                        .foregroundStyle(themeStore.secondaryText)
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                FormTextField(
                    title: String(localized: "Type the missing word"),
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

    private var clozeMatch: (range: Range<String.Index>, form: String)? {
        guard let example = item.example else { return nil }
        return ClozeMatcher.find(word: item.word, in: example)
    }

    private var clozeForm: String { clozeMatch?.form ?? item.word }

    private var clozeSentence: (before: String, after: String)? {
        guard let example = item.example, let match = clozeMatch else { return nil }
        let before = String(example[example.startIndex..<match.range.lowerBound])
        let after = String(example[match.range.upperBound..<example.endIndex])
        return (before, after)
    }

    private func clozeTextBlock(before: String, after: String) -> some View {
        let wordColor: Color = {
            if !hasAnswered { return themeStore.accentBlue }
            return themeStore.mainText
        }()

        return HStack(spacing: 0) {
            Text(before)
                .font(themeStore.regular(18))
                .foregroundStyle(themeStore.mainText)

            if clozeRevealed {
                Text(" \(item.word) ")
                    .font(themeStore.bold(18))
                    .foregroundStyle(wordColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(wordColor.opacity(0.12))
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                clozeBlank
            }

            Text(after)
                .font(themeStore.regular(18))
                .foregroundStyle(themeStore.mainText)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: clozeRevealed)
    }

    private var clozeBlank: some View {
        let firstLetter = clozeForm.first.map { String($0) } ?? ""
        let blanks = String(repeating: "_", count: max(2, clozeForm.count - 1))

        return HStack(spacing: 2) {
            Text(" \(firstLetter)")
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.accentBlue)
            Text("\(blanks) ")
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.accentBlue.opacity(0.4))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(themeStore.accentBlue.opacity(0.12))
        )
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
                    text: DuoChaosCopy.wrongReveal(item.word),
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
