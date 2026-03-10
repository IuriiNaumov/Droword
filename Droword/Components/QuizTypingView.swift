import SwiftUI

struct QuizTypingView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @StateObject private var session = QuizSessionManager()

    @State private var userInput: String = ""
    @State private var hasSubmitted = false
    @State private var isCorrect = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            if store.words.filter({ $0.translation != nil && !$0.translation!.isEmpty }).isEmpty {
                emptyState
            } else if session.isComplete {
                QuizCompletionView(
                    correct: session.correctCount,
                    total: session.total
                ) {
                    startSession()
                }
            } else if let item = session.currentItem {
                typingView(item: item)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.currentIndex)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.isComplete)
        .onAppear { startSession() }
        .onTapGesture { isInputFocused = false }
    }

    private func typingView(item: QuizSessionManager.QuizItem) -> some View {
        VStack(spacing: 0) {
            Text("\(session.currentIndex + 1) / \(session.total)")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.mainGrey)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 8) {
                Text(item.word)
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.mainBlack)
                    .multilineTextAlignment(.center)

                if let tr = item.transcription, !tr.isEmpty {
                    Text(tr)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)
                }

                Text("Type the translation")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.mainGrey.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                TextField("Your answer", text: $userInput)
                    .focused($isInputFocused)
                    .font(.custom("Poppins-Regular", size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 19)
                    .background(Color.cardBackground)
                    .foregroundColor(.mainBlack)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(borderColor, lineWidth: hasSubmitted ? 3 : 2)
                    )
                    .cornerRadius(20)
                    .disabled(hasSubmitted)
                    .submitLabel(.done)
                    .onSubmit {
                        if !hasSubmitted && !userInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            checkAnswer()
                        }
                    }

                if hasSubmitted && !isCorrect {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(darkerShade(of: Color.accentRed, by: 0.3))
                        Text("Correct: \(session.currentItem?.translation ?? "")")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(darkerShade(of: Color.accentGreen, by: 0.3))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentGreen.opacity(0.3))
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                if hasSubmitted && isCorrect {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(darkerShade(of: Color.accentGreen, by: 0.3))
                        Text("Correct!")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(darkerShade(of: Color.accentGreen, by: 0.3))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentGreen.opacity(0.3))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if !hasSubmitted {
                Button {
                    checkAnswer()
                } label: {
                    Text("Check")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(userInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.mainGrey.opacity(0.3)
                                    : Color.accentBlue)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else {
                Button {
                    goToNext()
                } label: {
                    Text("Next")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.accentBlue)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var borderColor: Color {
        if !hasSubmitted {
            return isInputFocused ? Color.accentBlue : Color.clear
        }
        return isCorrect ? Color.accentGreen : Color.accentRed
    }

    private func startSession() {
        session.prepareSession(from: store.words)
        userInput = ""
        hasSubmitted = false
        isCorrect = false
        isInputFocused = true
    }

    private func checkAnswer() {
        guard let item = session.currentItem else { return }
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        hasSubmitted = true
        isCorrect = trimmed.lowercased() == item.translation
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if isCorrect {
            Haptics.success()
        } else {
            Haptics.error()
        }

        session.recordAnswer(correct: isCorrect)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: isCorrect,
            store: store,
            languageStore: languageStore
        )

        isInputFocused = false
    }

    private func goToNext() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            session.advance()
        }
        userInput = ""
        hasSubmitted = false
        isCorrect = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isInputFocused = true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("No words to practice yet ✨")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Add some words with translations to start typing practice. You've got this!")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    QuizTypingView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
}
