import SwiftUI

struct QuizMixedView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @StateObject private var session = QuizSessionManager()

    var sessionSize: Int = 10
    var filterTag: String? = nil
    var direction: QuizDirection = .mixed

    @State private var hasAnswered = false
    @State private var isCorrect = false
    @State private var isAlmostCorrect = false

    @State private var options: [String] = []
    @State private var selectedOption: String? = nil
    @State private var mcReversed = false

    @State private var typingInput: String = ""
    @State private var typingReversed = false
    @FocusState private var isInputFocused: Bool
    @State private var feedbackBounce: CGFloat = 0.6

    var body: some View {
        ZStack {
            if store.words.filter({ $0.translation != nil && !$0.translation!.isEmpty }).count < 4 {
                notEnoughState
            } else if session.isComplete {
                QuizCompletionView(
                    correct: session.correctCount,
                    total: session.total
                ) {
                    startSession()
                }
            } else if let item = session.currentItem,
                      let exerciseType = session.currentExerciseType {
                VStack(spacing: 0) {
                    progressCounter

                    switch exerciseType {
                    case .multipleChoice:
                        multipleChoiceContent(item: item)
                    case .typing:
                        typingContent(item: item)
                    case .cloze:
                        clozeContent(item: item)
                    }

                    Spacer()
                    bottomButton(exerciseType: exerciseType)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.currentIndex)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.isComplete)
        .onAppear { startSession() }
        .onChange(of: session.isComplete) { _, isComplete in
            if isComplete {
                badgeStore.recordQuizCompletion()
                DailyChallengeManager.shared.recordQuizCompleted(
                    score: session.correctCount,
                    total: session.total
                )
            }
        }
        .onTapGesture { isInputFocused = false }
    }

    private var progressCounter: some View {
        Text("\(session.currentIndex + 1) / \(session.total)")
            .font(.custom("Poppins-Medium", size: 14))
            .foregroundColor(themeStore.secondaryText)
            .padding(.top, 8)
    }

    private func bottomButton(exerciseType: QuizSessionManager.ExerciseType) -> some View {
        Group {
            if (exerciseType == .typing || exerciseType == .cloze) && !hasAnswered {
                Button {
                    checkTypingAnswer()
                } label: {
                    Text("Check")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(typingInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? themeStore.secondaryText.opacity(0.3)
                                    : themeStore.buttonAccent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(typingInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else if hasAnswered {
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

    private func startSession() {
        session.maxSessionSize = sessionSize
        session.prepareMixedSession(from: store.words, filterTag: filterTag)
        prepareCurrentQuestion()
    }

    private func prepareCurrentQuestion() {
        hasAnswered = false
        isCorrect = false
        isAlmostCorrect = false
        selectedOption = nil
        typingInput = ""
        isInputFocused = false
        feedbackBounce = 0.6

        guard let item = session.currentItem,
              let exerciseType = session.currentExerciseType else { return }

        switch exerciseType {
        case .multipleChoice:
            switch direction {
            case .normal: mcReversed = false
            case .reversed: mcReversed = true
            case .mixed: mcReversed = Bool.random()
            }
            let distractors = session.distractors(for: item, from: store.words, reversed: mcReversed)
            let answer = mcReversed ? item.word : item.translation
            var all = distractors + [answer]
            all.shuffle()
            options = all

        case .typing:
            switch direction {
            case .normal: typingReversed = false
            case .reversed: typingReversed = true
            case .mixed: typingReversed = Bool.random()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }

        case .cloze:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }

    private func goToNext() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            session.advance()
        }
        prepareCurrentQuestion()
    }

    private func multipleChoiceContent(item: QuizSessionManager.QuizItem) -> some View {
        let prompt = mcReversed ? item.translation : item.word
        let correctAnswer = mcReversed ? item.word : item.translation

        return VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(prompt)
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(themeStore.mainText)
                    .multilineTextAlignment(.center)

                if !mcReversed, let tr = item.transcription, !tr.isEmpty {
                    Text(tr)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(themeStore.secondaryText)
                }

                Text(mcReversed ? "Choose the correct word" : "Choose the correct translation")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    mcOptionButton(option: option, correctAnswer: correctAnswer, item: item)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func mcOptionButton(option: String, correctAnswer: String, item: QuizSessionManager.QuizItem) -> some View {
        let isThisCorrect = option.lowercased() == correctAnswer.lowercased()
        let isSelected = selectedOption == option

        var bgColor: Color {
            if !hasAnswered { return themeStore.cardBg }
            if isThisCorrect { return themeStore.accentGreen }
            if isSelected && !isThisCorrect { return themeStore.accentRed }
            return themeStore.cardBg
        }

        var textColor: Color {
            if !hasAnswered { return themeStore.mainText }
            if isThisCorrect { return darkerShade(of: themeStore.accentGreen, by: 0.4) }
            if isSelected && !isThisCorrect { return darkerShade(of: themeStore.accentRed, by: 0.4) }
            return themeStore.mainText.opacity(0.4)
        }

        return Button {
            selectOption(option, correctAnswer: correctAnswer, item: item)
        } label: {
            HStack {
                Text(option)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(textColor)

                Spacer()

                if hasAnswered && isThisCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(darkerShade(of: themeStore.accentGreen, by: 0.3))
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(darkerShade(of: themeStore.accentRed, by: 0.3))
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
        .animation(.easeInOut(duration: 0.25), value: hasAnswered)
    }

    private func selectOption(_ option: String, correctAnswer: String, item: QuizSessionManager.QuizItem) {
        guard !hasAnswered else { return }
        Haptics.selection()
        selectedOption = option
        hasAnswered = true
        isCorrect = option.lowercased() == correctAnswer.lowercased()

        if isCorrect { Haptics.success() } else { Haptics.error() }

        session.recordAnswer(correct: isCorrect)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: isCorrect,
            store: store,
            languageStore: languageStore
        )
    }

    private func typingContent(item: QuizSessionManager.QuizItem) -> some View {
        let prompt = typingReversed ? item.translation : item.word
        let expected = typingReversed ? item.word : item.translation

        return VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(prompt)
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(themeStore.mainText)
                    .multilineTextAlignment(.center)

                if !typingReversed, let tr = item.transcription, !tr.isEmpty {
                    Text(tr)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(themeStore.secondaryText)
                }

                Text(typingReversed ? "Type the word" : "Type the translation")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                TextField("Your answer", text: $typingInput)
                    .focused($isInputFocused)
                    .font(.custom("Poppins-Regular", size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(themeStore.cardBg)
                    .foregroundColor(themeStore.mainText)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(typingBorderColor, lineWidth: hasAnswered ? 2 : 1.5)
                    )
                    .cornerRadius(14)
                    .disabled(hasAnswered)
                    .submitLabel(.done)
                    .onSubmit {
                        if !hasAnswered && !typingInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            checkTypingAnswer()
                        }
                    }

                typingFeedback(expected: expected)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func clozeContent(item: QuizSessionManager.QuizItem) -> some View {
        VStack(spacing: 0) {
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
                        Text(" _____ ")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(themeStore.accentBlue)
                        Text(parts.after)
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(themeStore.mainText)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                }

                if !item.translation.isEmpty {
                    Text("(\(item.translation))")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(themeStore.secondaryText)
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                TextField("Type the missing word", text: $typingInput)
                    .focused($isInputFocused)
                    .font(.custom("Poppins-Regular", size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(themeStore.cardBg)
                    .foregroundColor(themeStore.mainText)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(typingBorderColor, lineWidth: hasAnswered ? 2 : 1.5)
                    )
                    .cornerRadius(14)
                    .disabled(hasAnswered)
                    .submitLabel(.done)
                    .onSubmit {
                        if !hasAnswered && !typingInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            checkTypingAnswer()
                        }
                    }

                clozeFeedback(item: item)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func clozeSentence(for item: QuizSessionManager.QuizItem) -> (before: String, after: String)? {
        guard let example = item.example else { return nil }
        guard let range = example.range(of: item.word, options: .caseInsensitive) else { return nil }
        let before = String(example[example.startIndex..<range.lowerBound])
        let after = String(example[range.upperBound..<example.endIndex])
        return (before, after)
    }

    private var typingBorderColor: Color {
        if !hasAnswered {
            return isInputFocused ? themeStore.mainText : themeStore.dividerColor
        }
        if isAlmostCorrect { return themeStore.accentGold }
        return isCorrect ? themeStore.accentGreen : themeStore.accentRed
    }

    private func typingFeedback(expected: String) -> some View {
        Group {
            if hasAnswered && isAlmostCorrect {
                feedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Almost! Answer: \(expected)",
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && !isCorrect && !isAlmostCorrect {
                feedbackBadge(
                    icon: "xmark.circle.fill",
                    text: "Correct: \(expected)",
                    color: themeStore.accentRed
                )
            }

            if hasAnswered && isCorrect && !isAlmostCorrect {
                feedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Correct!",
                    color: themeStore.accentGreen
                )
            }
        }
    }

    private func clozeFeedback(item: QuizSessionManager.QuizItem) -> some View {
        Group {
            if hasAnswered && isAlmostCorrect {
                feedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Almost! Answer: \(item.word)",
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && !isCorrect && !isAlmostCorrect {
                feedbackBadge(
                    icon: "xmark.circle.fill",
                    text: "Correct: \(item.word)",
                    color: themeStore.accentRed
                )
            }

            if hasAnswered && isCorrect && !isAlmostCorrect {
                feedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Correct!",
                    color: themeStore.accentGreen
                )
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
        .scaleEffect(feedbackBounce)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            feedbackBounce = 0.6
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                feedbackBounce = 1.0
            }
        }
    }

    private func checkTypingAnswer() {
        guard let item = session.currentItem,
              let exerciseType = session.currentExerciseType else { return }
        let trimmed = typingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let answer: String
        switch exerciseType {
        case .cloze:
            answer = item.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        case .typing:
            let expected = typingReversed ? item.word : item.translation
            answer = expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        default:
            return
        }

        let input = trimmed.lowercased()
        hasAnswered = true
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

        if isCorrect { Haptics.success() } else { Haptics.error() }

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

    private var notEnoughState: some View {
        VStack(spacing: 18) {
            Text("Not enough words yet")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Add at least 4 words with translations to start practicing. Every word counts!")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    QuizMixedView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
}
