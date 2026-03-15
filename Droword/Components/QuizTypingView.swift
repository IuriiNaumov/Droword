import SwiftUI

struct QuizTypingView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @StateObject private var session = QuizSessionManager()

    var sessionSize: Int = 10
    var filterTag: String? = nil
    var reversed: Bool = false

    @State private var userInput: String = ""
    @State private var hasSubmitted = false
    @State private var isCorrect = false
    @State private var isAlmostCorrect = false
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

    private func promptText(for item: QuizSessionManager.QuizItem) -> String {
        reversed ? item.translation : item.word
    }

    private func expectedAnswer(for item: QuizSessionManager.QuizItem) -> String {
        reversed ? item.word : item.translation
    }

    private func typingView(item: QuizSessionManager.QuizItem) -> some View {
        VStack(spacing: 0) {
            Text("\(session.currentIndex + 1) / \(session.total)")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.mainGrey)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 8) {
                Text(promptText(for: item))
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.mainBlack)
                    .multilineTextAlignment(.center)

                if !reversed, let tr = item.transcription, !tr.isEmpty {
                    Text(tr)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)
                }

                Text(reversed ? "Type the word" : "Type the translation")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.mainGrey.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                TextField("Your answer", text: $userInput)
                    .focused($isInputFocused)
                    .font(.custom("Poppins-Regular", size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(Color.cardBackground)
                    .foregroundColor(.mainBlack)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor, lineWidth: hasSubmitted ? 2 : 1.5)
                    )
                    .cornerRadius(14)
                    .disabled(hasSubmitted)
                    .submitLabel(.done)
                    .onSubmit {
                        if !hasSubmitted && !userInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            checkAnswer()
                        }
                    }

                if hasSubmitted && isAlmostCorrect {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(darkerShade(of: themeStore.accentGold, by: 0.3))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Almost correct!")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(darkerShade(of: themeStore.accentGold, by: 0.3))
                            if let item = session.currentItem {
                                Text("Answer: \(expectedAnswer(for: item))")
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .foregroundColor(darkerShade(of: themeStore.accentGold, by: 0.2))
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(themeStore.accentGold.opacity(0.3))
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                if hasSubmitted && !isCorrect && !isAlmostCorrect {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(darkerShade(of: themeStore.accentRed, by: 0.3))
                        if let item = session.currentItem {
                            Text("Correct: \(expectedAnswer(for: item))")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(darkerShade(of: themeStore.accentGreen, by: 0.3))
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(themeStore.accentGreen.opacity(0.3))
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                if hasSubmitted && isCorrect && !isAlmostCorrect {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(darkerShade(of: themeStore.accentGreen, by: 0.3))
                        Text("Correct!")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(darkerShade(of: themeStore.accentGreen, by: 0.3))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(themeStore.accentGreen.opacity(0.3))
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
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(userInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.mainGrey.opacity(0.3)
                                    : themeStore.buttonAccent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else {
                Button {
                    Haptics.lightImpact()
                    goToNext()
                } label: {
                    Text("Next")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themeStore.buttonAccent)
                        )
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
            return isInputFocused ? Color.mainBlack : Color.divider
        }
        if isAlmostCorrect { return themeStore.accentGold }
        return isCorrect ? themeStore.accentGreen : themeStore.accentRed
    }

    private func startSession() {
        session.maxSessionSize = sessionSize
        session.prepareSession(from: store.words, filterTag: filterTag)
        userInput = ""
        hasSubmitted = false
        isCorrect = false
        isAlmostCorrect = false
        isInputFocused = true
    }

    private func checkAnswer() {
        guard let item = session.currentItem else { return }
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let answer = expectedAnswer(for: item)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let input = trimmed.lowercased()

        hasSubmitted = true
        isCorrect = input == answer
        isAlmostCorrect = false

        if !isCorrect {
            let dist = levenshteinDistance(input, answer)
            let threshold = max(1, answer.count / 4)
            if dist <= threshold {
                isAlmostCorrect = true
                isCorrect = true
            }
        }

        if isCorrect {
            Haptics.success()
        } else {
            Haptics.error()
        }

        session.recordAnswer(correct: isCorrect)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: isCorrect,
            isAlmostCorrect: isAlmostCorrect,
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
        isAlmostCorrect = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isInputFocused = true
        }
    }

    private func levenshteinDistance(_ s: String, _ t: String) -> Int {
        let sArr = Array(s)
        let tArr = Array(t)
        let m = sArr.count
        let n = tArr.count

        if m == 0 { return n }
        if n == 0 { return m }

        var prev = Array(0...n)
        var curr = [Int](repeating: 0, count: n + 1)

        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = sArr[i - 1] == tArr[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,
                    curr[j - 1] + 1,
                    prev[j - 1] + cost
                )
            }
            prev = curr
        }
        return prev[n]
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
