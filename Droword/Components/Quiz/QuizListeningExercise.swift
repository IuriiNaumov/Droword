import SwiftUI

struct QuizListeningExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject private var network = NetworkMonitor.shared

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
                .opacity(network.isConnected ? 1 : 0.35)
                .disabled(!network.isConnected || isPlaying)
                .accessibilityLabel(Text("Play the word"))
                .accessibilityHint(
                    Text(network.isConnected
                         ? "Plays the word out loud"
                         : "Needs an internet connection")
                )

                Text(network.isConnected ? "Tap to hear it again" : "Needs an internet connection")
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

    private func play() {
        guard network.isConnected, !isPlaying else { return }
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
                        .foregroundStyle(themeStore.accentGreen)
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeStore.accentRed)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                    .fill(bgColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
        .opacity(isIrrelevant ? 0.4 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: hasAnswered)
        .accessibilityLabel(Text(option))
    }
}

#Preview {
    QuizListeningExercise(
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
        options: ["hello", "bye", "please", "thanks"],
        selectedOption: nil,
        shakeOffset: 0,
        onSelect: { _ in }
    )
    .padding()
    .environmentObject(ThemeStore())
}
