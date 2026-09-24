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
                Text(prompt.displayCapitalized)
                    .font(themeStore.bold(28))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.center)

                if !isReversed, let tr = item.transcription, !tr.isEmpty {
                    Text("[\(tr)]")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                }

                Text(isReversed ? "Choose the correct word" : "Choose the correct translation")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))
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

            if hasAnswered {
                Group {
                    if isCorrect {
                        QuizFeedbackBadge(
                            icon: "checkmark.circle.fill",
                            text: DuoChaosCopy.correct(),
                            color: themeStore.accentGreen
                        )
                    } else {
                        QuizFeedbackBadge(
                            icon: "xmark.circle.fill",
                            text: DuoChaosCopy.wrongReveal(correctAnswer),
                            color: themeStore.accentRed
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .transition(.opacity.combined(with: .scale))
            }

            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hasAnswered)
    }

    private func optionButton(option: String) -> some View {
        let isThisCorrect = option.lowercased() == correctAnswer.lowercased()
        let isSelected = selectedOption == option
        let isIrrelevant = hasAnswered && !isThisCorrect && !isSelected

        let bgColor: Color = {
            if !hasAnswered {
                return themeStore.isGlass ? Color.clear : themeStore.cardBg
            }
            if isThisCorrect {
                return themeStore.isGlass ? themeStore.accentGreen.opacity(0.35) : themeStore.accentGreen
            }
            if isSelected && !isThisCorrect {
                return themeStore.isGlass ? themeStore.accentRed.opacity(0.35) : themeStore.accentRed
            }
            return themeStore.isGlass ? Color.clear : themeStore.cardBg
        }()

        let textColor: Color = {
            if !hasAnswered { return themeStore.mainText }
            if isThisCorrect { return themeStore.mainText }
            if isSelected && !isThisCorrect { return themeStore.mainText }
            return themeStore.mainText.opacity(0.4)
        }()

        return Button {
            onSelect(option)
        } label: {
            HStack {
                Text(option.displayCapitalized)
                    .font(themeStore.medium(16))
                    .foregroundStyle(textColor)

                Spacer()

                if hasAnswered && isThisCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeStore.accentGreen)
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeStore.mainText)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                    .fill(bgColor)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
        .opacity(isIrrelevant ? 0.4 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: hasAnswered)
        .accessibilityLabel(Text(option))
        .accessibilityAddTraits(hasAnswered && isThisCorrect ? .isSelected : [])
    }
}

#Preview {
    QuizMultipleChoiceExercise(
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
        isReversed: false,
        options: ["hello", "bye", "please", "thanks"],
        selectedOption: nil,
        shakeOffset: 0,
        onSelect: { _ in }
    )
    .padding()
    .environmentObject(ThemeStore())
}
