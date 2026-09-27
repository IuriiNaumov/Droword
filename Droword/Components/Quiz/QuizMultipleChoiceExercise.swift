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
                        QuizCorrectFeedbackBadge()
                    } else {
                        QuizFeedbackBadge(
                            icon: "xmark.circle.fill",
                            text: DuoChaosCopy.wrongReveal(correctAnswer),
                            color: themeStore.errorStrong
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
        let duo = themeStore.isDuolingo && !themeStore.isGlass
        let radius = themeStore.controlRadius

        let bgColor: Color = {
            if !hasAnswered {
                return themeStore.isGlass ? Color.clear : (duo ? themeStore.controlFace : themeStore.cardBg)
            }
            if isThisCorrect {
                return themeStore.isGlass ? themeStore.successStrong.opacity(0.28) : themeStore.successSoft
            }
            if isSelected && !isThisCorrect {
                return themeStore.isGlass ? themeStore.errorStrong.opacity(0.28) : themeStore.errorSoft
            }
            return themeStore.isGlass ? Color.clear : (duo ? themeStore.controlFace : themeStore.cardBg)
        }()

        let textColor: Color = {
            if !hasAnswered { return themeStore.mainText }
            if isThisCorrect || (isSelected && !isThisCorrect) { return themeStore.mainText }
            return themeStore.mainText.opacity(0.4)
        }()

        let borderColor: Color? = {
            guard duo else { return nil }
            if hasAnswered, isThisCorrect { return themeStore.successStrong }
            if hasAnswered, isSelected && !isThisCorrect { return themeStore.errorStrong }
            return themeStore.dividerColor
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
                        .foregroundStyle(themeStore.successStrong)
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeStore.errorStrong)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    if duo {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(Color(hex: "#AFAFAF").opacity(0.45))
                            .offset(y: 3)
                    }
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(bgColor)
                }
            )
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 2)
                }
            }
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: radius))
            .padding(.bottom, duo ? 3 : 0)
        }
        .buttonStyle(Duo3DButtonStyle())
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
