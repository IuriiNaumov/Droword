import SwiftUI

struct QuizClozeView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @StateObject private var session = QuizSessionManager()

    var sessionSize: Int = 10
    var filterTag: String? = nil

    @State private var userInput: String = ""
    @State private var hasSubmitted = false
    @State private var isCorrect = false
    @State private var isAlmostCorrect = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            if eligibleWords.count < 1 {
                emptyState
            } else if session.isComplete {
                QuizCompletionView(
                    correct: session.correctCount,
                    total: session.total
                ) {
                    startSession()
                }
            } else if let item = session.currentItem {
                clozeView(item: item)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.currentIndex)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.isComplete)
        .onAppear { startSession() }
        .onTapGesture { isInputFocused = false }
    }

    private var eligibleWords: [StoredWord] {
        store.words.filter { w in
            guard let example = w.example, !example.isEmpty else { return false }
            guard w.translation != nil, !w.translation!.isEmpty else { return false }
            return example.localizedCaseInsensitiveContains(w.word)
        }
    }

    private func clozeSentence(for item: QuizSessionManager.QuizItem) -> (before: String, after: String)? {
        guard let example = item.example else { return nil }
        guard let range = example.range(of: item.word, options: .caseInsensitive) else { return nil }
        let before = String(example[example.startIndex..<range.lowerBound])
        let after = String(example[range.upperBound..<example.endIndex])
        return (before, after)
    }

    private func clozeView(item: QuizSessionManager.QuizItem) -> some View {
        VStack(spacing: 0) {
            Text("\(session.currentIndex + 1) / \(session.total)")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(themeStore.secondaryText)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 12) {
                Text("Fill in the blank")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))

                if let parts = clozeSentence(for: item) {
                    HStack(spacing: 0) {
                        Text(parts.before)
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(themeStore.mainText)

                        if hasSubmitted && isCorrect {
                            Text(" \(item.word) ")
                                .font(.custom("Poppins-Bold", size: 18))
                                .foregroundColor(isAlmostCorrect
                                    ? darkerShade(of: themeStore.accentGold, by: 0.2)
                                    : darkerShade(of: themeStore.accentGreen, by: 0.2))
                                .transition(.scale.combined(with: .opacity))
                        } else if hasSubmitted && !isCorrect {
                            Text(" \(item.word) ")
                                .font(.custom("Poppins-Bold", size: 18))
                                .foregroundColor(darkerShade(of: themeStore.accentRed, by: 0.2))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text(" _____ ")
                                .font(.custom("Poppins-Bold", size: 18))
                                .foregroundColor(themeStore.accentBlue)
                        }

                        Text(parts.after)
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(themeStore.mainText)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasSubmitted)
                }

                if let translation = item.translation.nilIfEmpty {
                    Text("(\(translation))")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(themeStore.secondaryText)
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                TextField("Type the missing word", text: $userInput)
                    .focused($isInputFocused)
                    .font(.custom("Poppins-Regular", size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(themeStore.cardBg)
                    .foregroundColor(themeStore.mainText)
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
                    feedbackBadge(
                        icon: "checkmark.circle.fill",
                        text: "Almost! Answer: \(item.word)",
                        color: themeStore.accentGold
                    )
                }

                if hasSubmitted && !isCorrect && !isAlmostCorrect {
                    feedbackBadge(
                        icon: "xmark.circle.fill",
                        text: "Correct: \(item.word)",
                        color: themeStore.accentRed
                    )
                }

                if hasSubmitted && isCorrect && !isAlmostCorrect {
                    feedbackBadge(
                        icon: "checkmark.circle.fill",
                        text: "Correct!",
                        color: themeStore.accentGreen
                    )
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
                                    ? themeStore.secondaryText.opacity(0.3)
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

    private func feedbackBadge(icon: String, text: String, iconColor: Color? = nil, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(darkerShade(of: iconColor ?? color, by: 0.3))
            Text(text)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(darkerShade(of: color, by: 0.3))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.3))
        )
        .transition(.scale.combined(with: .opacity))
    }

    private var borderColor: Color {
        if !hasSubmitted {
            return isInputFocused ? themeStore.mainText : themeStore.dividerColor
        }
        if isAlmostCorrect { return themeStore.accentGold }
        return isCorrect ? themeStore.accentGreen : themeStore.accentRed
    }

    private func startSession() {
        let eligible = eligibleWords
        session.maxSessionSize = sessionSize
        session.prepareSession(from: eligible, filterTag: filterTag)
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

        let answer = item.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
            Text("No cloze words yet")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Add words with example sentences that contain the word to start cloze practice.")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    QuizClozeView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
}
