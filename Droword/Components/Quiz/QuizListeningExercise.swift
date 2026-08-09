import SwiftUI

/// Упражнение на аудирование: проигрывается озвучка слова, пользователь выбирает
/// правильное написание среди вариантов. Проверка идёт через тот же `onSelect`,
/// что и у обычного multiple-choice (в родителе для этого типа `mcReversed = true`,
/// поэтому правильный ответ — само слово).
struct QuizListeningExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let options: [String]
    let selectedOption: String?
    let shakeOffset: CGFloat

    var onSelect: (String) -> Void

    @State private var isPlaying = false

    private var correctAnswer: String { item.word }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Button {
                    play()
                } label: {
                    SoundWavesView(isPlaying: isPlaying)
                        .scaleEffect(2.2)
                        .frame(width: 96, height: 96)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(Text("Play the word"))

                Text("Tap to hear it again")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))
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

    private func play() {
        guard !isPlaying else { return }
        isPlaying = true
        Task {
            try? await AudioManager.shared.playAndWait(text: item.word)
            await MainActor.run { isPlaying = false }
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

        return Button {
            onSelect(option)
        } label: {
            HStack {
                Text(option)
                    .font(themeStore.medium(16))
                    .foregroundStyle(hasAnswered && isIrrelevant ? themeStore.mainText.opacity(0.4) : themeStore.mainText)

                Spacer()

                if hasAnswered && isThisCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeStore.mainText)
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(bgColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
        .opacity(isIrrelevant ? 0.4 : 1.0)
        .scaleEffect(hasAnswered && isThisCorrect ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: hasAnswered)
        .accessibilityLabel(Text(option))
    }
}
