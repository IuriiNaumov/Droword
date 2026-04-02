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

            VStack(spacing: 12) {
                Text("Fill in the blank")
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))

                if let parts = clozeSentence {
                    clozeTextBlock(before: parts.before, after: parts.after)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                if !item.translation.isEmpty {
                    Text("(\(item.translation))")
                        .font(themeStore.medium(16))
                        .foregroundColor(themeStore.secondaryText)
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                TextField("Type the missing word", text: $typingInput)
                    .focused(isInputFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(themeStore.regular(16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(fieldBackground)
                    .foregroundColor(themeStore.mainText)
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

    private var clozeSentence: (before: String, after: String)? {
        guard let example = item.example else { return nil }
        guard let range = example.range(of: item.word, options: .caseInsensitive) else { return nil }
        let before = String(example[example.startIndex..<range.lowerBound])
        let after = String(example[range.upperBound..<example.endIndex])
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
                .foregroundColor(themeStore.mainText)

            if clozeRevealed {
                Text(" \(item.word) ")
                    .font(themeStore.bold(18))
                    .foregroundColor(wordColor)
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
                .foregroundColor(themeStore.mainText)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: clozeRevealed)
    }

    private var clozeBlank: some View {
        let firstLetter = item.word.first.map { String($0) } ?? ""
        let blanks = String(repeating: "_", count: max(2, item.word.count - 1))

        return HStack(spacing: 2) {
            Text(" \(firstLetter)")
                .font(themeStore.bold(18))
                .foregroundColor(themeStore.accentBlue)
            Text("\(blanks) ")
                .font(themeStore.bold(18))
                .foregroundColor(themeStore.accentBlue.opacity(0.4))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(themeStore.accentBlue.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        )
    }

    private var feedback: some View {
        Group {
            if !hasAnswered && hintShown {
                QuizFeedbackBadge(
                    icon: "lightbulb.fill",
                    text: "Hint: \(hintText)",
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Almost!",
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && !isCorrect && !isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "xmark.circle.fill",
                    text: "Correct: \(item.word)",
                    color: themeStore.accentRed
                )
            }

            if hasAnswered && isCorrect && !isAlmostCorrect {
                QuizFeedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Correct!",
                    color: themeStore.accentGreen
                )
            }
        }
    }
}
