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
    @State private var clozeRevealed = false

    // Shake animation for wrong answers
    @State private var shakeOffset: CGFloat = 0

    // Hint system for typing/cloze
    @State private var hintShown = false
    @State private var hintText: String = ""

    // Matching mode
    @State private var matchingPairs: [(word: String, translation: String)] = []
    @State private var matchedPairs: Set<String> = []  // matched word keys
    @State private var selectedMatchWord: String? = nil
    @State private var matchingWrongPair: (String, String)? = nil

    // Sentence building
    @State private var sentenceWords: [String] = []  // shuffled words
    @State private var selectedSentenceWords: [String] = []  // user's built sentence
    @State private var correctSentenceWords: [String] = []  // correct order

    // Streak animation
    @State private var streakScale: CGFloat = 1.0
    @State private var streakMilestone: Int? = nil
    @State private var streakMilestoneOpacity: Double = 0

    var body: some View {
        ZStack {
            if store.words.filter({ $0.translation != nil && !$0.translation!.isEmpty }).count < 4 {
                notEnoughState
            } else if session.isComplete {
                QuizCompletionView(
                    correct: session.correctCount,
                    total: session.total,
                    bestStreak: session.bestStreak,
                    missedWords: session.queue.compactMap { item in
                        if session.answerResults[item.id] == false {
                            return (word: item.word, translation: item.translation)
                        }
                        return nil
                    }
                ) {
                    startSession()
                }
            } else if let item = session.currentItem,
                      let exerciseType = session.currentExerciseType {
                VStack(spacing: 0) {
                    progressHeader

                    switch exerciseType {
                    case .multipleChoice:
                        multipleChoiceContent(item: item)
                    case .typing:
                        typingContent(item: item)
                    case .cloze:
                        clozeContent(item: item)
                    case .matching:
                        matchingContent(item: item)
                    case .sentenceBuilding:
                        sentenceBuildingContent(item: item)
                    }

                    Spacer(minLength: 0)

                    bottomButton(exerciseType: exerciseType)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .overlay(alignment: .top) {
            if let milestone = streakMilestone {
                streakMilestoneBanner(streak: milestone)
                    .opacity(streakMilestoneOpacity)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
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

    // MARK: - Progress Header with Streak

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(session.currentIndex + 1) / \(session.total)")
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(themeStore.secondaryText)

                Spacer()

                // Streak counter
                if session.currentStreak >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(streakColor)
                        Text("\(session.currentStreak)")
                            .font(.custom("Poppins-Bold", size: 14))
                            .foregroundColor(streakColor)
                    }
                    .scaleEffect(streakScale)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)

            // Segmented progress bar
            segmentedProgressBar
        }
        .padding(.top, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: session.currentStreak)
    }

    private var streakColor: Color {
        switch session.currentStreak {
        case 2...4: return .orange
        case 5...9: return .red
        default: return .red
        }
    }

    private var segmentedProgressBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(0..<session.total, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(segmentColor(for: index))
                        .frame(height: 6)
                }
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.3), value: session.answerResults)
        .animation(.easeInOut(duration: 0.3), value: session.currentIndex)
    }

    private func segmentColor(for index: Int) -> Color {
        let item = index < session.queue.count ? session.queue[index] : nil
        if let item, let result = session.answerResults[item.id] {
            return result ? themeStore.accentGreen : themeStore.accentRed
        }
        if index == session.currentIndex {
            return themeStore.buttonAccent.opacity(0.5)
        }
        return themeStore.dividerColor.opacity(0.4)
    }

    // MARK: - Bottom Button

    private func bottomButton(exerciseType: QuizSessionManager.ExerciseType) -> some View {
        Group {
            if exerciseType == .matching && !hasAnswered {
                // Matching auto-advances, no button needed
                EmptyView()
            } else if exerciseType == .sentenceBuilding && !hasAnswered {
                VStack(spacing: 10) {
                    Button {
                        checkSentenceAnswer()
                    } label: {
                        Text("Check")
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedSentenceWords.isEmpty
                                        ? themeStore.secondaryText.opacity(0.3)
                                        : themeStore.buttonAccent)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedSentenceWords.isEmpty)

                    Button {
                        skipQuestion()
                    } label: {
                        Text("Don't know")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(themeStore.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else if (exerciseType == .typing || exerciseType == .cloze) && !hasAnswered {
                VStack(spacing: 10) {
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

                    Button {
                        skipQuestion()
                    } label: {
                        Text(hintShown ? "Show answer" : "Don't know")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(themeStore.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else if hasAnswered {
                Button {
                    Haptics.lightImpact()
                    goToNext()
                } label: {
                    Text("Continue")
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

    private func skipQuestion() {
        guard let item = session.currentItem else { return }
        Haptics.error()
        hasAnswered = true
        isCorrect = false
        isAlmostCorrect = false
        typingInput = ""

        if session.currentExerciseType == .cloze {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                clozeRevealed = true
            }
        }

        triggerShake()

        session.recordAnswer(correct: false)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: false,
            store: store,
            languageStore: languageStore
        )
        isInputFocused = false
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
        clozeRevealed = false
        shakeOffset = 0
        hintShown = false
        hintText = ""

        guard let item = session.currentItem,
              let exerciseType = session.currentExerciseType else { return }

        switch exerciseType {
        case .multipleChoice:
            switch direction {
            case .normal: mcReversed = false
            case .reversed: mcReversed = true
            case .mixed: mcReversed = session.directionMap[item.id] ?? Bool.random()
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
            case .mixed: typingReversed = session.directionMap[item.id] ?? Bool.random()
            }

        case .cloze:
            break

        case .matching:
            matchingPairs = session.matchingPairs(for: item)
            matchedPairs = []
            selectedMatchWord = nil
            matchingWrongPair = nil

        case .sentenceBuilding:
            if let example = item.example {
                correctSentenceWords = example.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                sentenceWords = correctSentenceWords.shuffled()
                // Reshuffle if accidentally in correct order
                if sentenceWords == correctSentenceWords && sentenceWords.count > 1 {
                    sentenceWords.shuffle()
                }
            } else {
                correctSentenceWords = []
                sentenceWords = []
            }
            selectedSentenceWords = []
        }
    }

    private func goToNext() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            session.advance()
        }
        prepareCurrentQuestion()
    }

    // MARK: - Shake Animation

    private func triggerShake() {
        withAnimation(.default) {
            shakeOffset = 12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = 6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) { shakeOffset = -3 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.default) { shakeOffset = 0 }
        }
    }

    // MARK: - Multiple Choice

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
            .offset(x: hasAnswered && !isCorrect ? shakeOffset : 0)

            Spacer()
        }
    }

    private func mcOptionButton(option: String, correctAnswer: String, item: QuizSessionManager.QuizItem) -> some View {
        let isThisCorrect = option.lowercased() == correctAnswer.lowercased()
        let isSelected = selectedOption == option
        let isIrrelevant = hasAnswered && !isThisCorrect && !isSelected

        var bgColor: Color {
            if !hasAnswered { return themeStore.cardBg }
            if isThisCorrect { return themeStore.accentGreen }
            if isSelected && !isThisCorrect { return themeStore.accentRed }
            return themeStore.cardBg
        }

        var textColor: Color {
            if !hasAnswered { return themeStore.mainText }
            if isThisCorrect { return themeStore.mainText }
            if isSelected && !isThisCorrect { return themeStore.mainText }
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
                        .foregroundColor(themeStore.mainText)
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeStore.mainText)
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
        .animation(.easeInOut(duration: 0.25), value: hasAnswered)
    }

    private func selectOption(_ option: String, correctAnswer: String, item: QuizSessionManager.QuizItem) {
        guard !hasAnswered else { return }
        Haptics.selection()
        selectedOption = option
        hasAnswered = true
        isCorrect = option.lowercased() == correctAnswer.lowercased()

        if isCorrect {
            Haptics.success()
            animateStreakPulse()
        } else {
            Haptics.error()
            triggerShake()
        }

        session.recordAnswer(correct: isCorrect)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: isCorrect,
            store: store,
            languageStore: languageStore
        )
    }

    // MARK: - Matching

    private func matchingContent(item: QuizSessionManager.QuizItem) -> some View {
        let words = matchingPairs.map(\.word)
        let translations = matchingPairs.map(\.translation).shuffled()

        return VStack(spacing: 0) {
            Spacer()

            Text("Match the pairs")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(themeStore.secondaryText.opacity(0.7))
                .padding(.bottom, 24)

            HStack(spacing: 12) {
                // Words column
                VStack(spacing: 10) {
                    ForEach(words, id: \.self) { word in
                        matchingWordCell(text: word, isWord: true)
                    }
                }

                // Translations column
                VStack(spacing: 10) {
                    ForEach(translations, id: \.self) { translation in
                        matchingWordCell(text: translation, isWord: false)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func matchingWordCell(text: String, isWord: Bool) -> some View {
        let isMatched = matchedPairs.contains(text)
        let isSelected = isWord && selectedMatchWord == text
        let isWrong = matchingWrongPair?.0 == text || matchingWrongPair?.1 == text

        var bgColor: Color {
            if isMatched { return themeStore.accentGreen.opacity(0.2) }
            if isWrong { return themeStore.accentRed.opacity(0.2) }
            if isSelected { return themeStore.buttonAccent.opacity(0.15) }
            return themeStore.cardBg
        }

        var borderColor: Color {
            if isMatched { return themeStore.accentGreen }
            if isWrong { return themeStore.accentRed }
            if isSelected { return themeStore.buttonAccent }
            return themeStore.dividerColor
        }

        return Button {
            handleMatchingTap(text: text, isWord: isWord)
        } label: {
            Text(text)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(isMatched ? themeStore.secondaryText : themeStore.mainText)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(bgColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .opacity(isMatched ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.2), value: isMatched)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func handleMatchingTap(text: String, isWord: Bool) {
        guard !hasAnswered else { return }

        if isWord {
            // Select/deselect a word
            if selectedMatchWord == text {
                selectedMatchWord = nil
            } else {
                selectedMatchWord = text
            }
            Haptics.selection()
        } else {
            // Tapped a translation — check if a word is selected
            guard let word = selectedMatchWord else { return }
            let translation = text

            // Find if this is a correct pair
            let isCorrectPair = matchingPairs.contains { $0.word == word && $0.translation == translation }

            if isCorrectPair {
                Haptics.success()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    matchedPairs.insert(word)
                    matchedPairs.insert(translation)
                    selectedMatchWord = nil
                }

                // Check if all matched
                if matchedPairs.count == matchingPairs.count * 2 {
                    hasAnswered = true
                    isCorrect = true
                    session.recordAnswer(correct: true)
                    animateStreakPulse()
                    if let item = session.currentItem {
                        QuizSessionManager.applyScheduling(
                            for: item.id,
                            correct: true,
                            store: store,
                            languageStore: languageStore
                        )
                    }
                }
            } else {
                Haptics.error()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    matchingWrongPair = (word, translation)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { matchingWrongPair = nil }
                }
                selectedMatchWord = nil
            }
        }
    }

    // MARK: - Sentence Building

    private func sentenceBuildingContent(item: QuizSessionManager.QuizItem) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Build the sentence")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))

                Text(item.translation)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(themeStore.mainText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)

            // Built sentence area
            sentenceBuiltArea
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // Available words
            sentenceWordBank
                .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var sentenceBuiltArea: some View {
        let borderColor: Color = {
            if !hasAnswered { return themeStore.dividerColor }
            return isCorrect ? themeStore.accentGreen : themeStore.accentRed
        }()

        return VStack(spacing: 8) {
            FlowLayout(spacing: 8) {
                if selectedSentenceWords.isEmpty {
                    Text("Tap words to build the sentence")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(themeStore.secondaryText.opacity(0.4))
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(selectedSentenceWords.enumerated()), id: \.offset) { index, word in
                        Button {
                            guard !hasAnswered else { return }
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSentenceWords.remove(at: index)
                                sentenceWords.append(word)
                            }
                        } label: {
                            Text(word)
                                .font(.custom("Poppins-Medium", size: 15))
                                .foregroundColor(themeStore.mainText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(themeStore.buttonAccent.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(hasAnswered)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(themeStore.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: hasAnswered ? 2 : 1)
            )

            if hasAnswered && !isCorrect {
                feedbackBadge(
                    icon: "xmark.circle.fill",
                    text: correctSentenceWords.joined(separator: " "),
                    color: themeStore.accentRed
                )
            }

            if hasAnswered && isCorrect {
                feedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Correct!",
                    color: themeStore.accentGreen
                )
            }
        }
        .offset(x: hasAnswered && !isCorrect ? shakeOffset : 0)
    }

    private var sentenceWordBank: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(sentenceWords.enumerated()), id: \.offset) { index, word in
                Button {
                    guard !hasAnswered else { return }
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sentenceWords.remove(at: index)
                        selectedSentenceWords.append(word)
                    }
                } label: {
                    Text(word)
                        .font(.custom("Poppins-Medium", size: 15))
                        .foregroundColor(themeStore.mainText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(themeStore.cardBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(themeStore.dividerColor, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(hasAnswered)
            }
        }
    }

    private func checkSentenceAnswer() {
        guard let item = session.currentItem else { return }
        hasAnswered = true
        isCorrect = selectedSentenceWords == correctSentenceWords

        if isCorrect {
            Haptics.success()
            animateStreakPulse()
        } else {
            Haptics.error()
            triggerShake()
        }

        session.recordAnswer(correct: isCorrect)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: isCorrect,
            store: store,
            languageStore: languageStore
        )
    }

    // MARK: - Typing

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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.custom("Poppins-Regular", size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(typingFieldBackground)
                    .foregroundColor(themeStore.mainText)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(typingBorderColor, lineWidth: hasAnswered ? 2.5 : 1.5)
                    )
                    .cornerRadius(14)
                    .disabled(hasAnswered)
                    .submitLabel(.done)
                    .onSubmit {
                        if !hasAnswered && !typingInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            checkTypingAnswer()
                        }
                    }
                    .offset(x: shakeOffset)

                typingFeedback(expected: expected)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var typingFieldBackground: Color {
        if !hasAnswered { return themeStore.cardBg }
        if isAlmostCorrect { return themeStore.accentGold.opacity(0.08) }
        if isCorrect { return themeStore.accentGreen.opacity(0.08) }
        return themeStore.accentRed.opacity(0.08)
    }

    // MARK: - Cloze

    private func clozeContent(item: QuizSessionManager.QuizItem) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("Fill in the blank")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))

                if let parts = clozeSentence(for: item) {
                    clozeTextBlock(item: item, before: parts.before, after: parts.after)
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.custom("Poppins-Regular", size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(typingFieldBackground)
                    .foregroundColor(themeStore.mainText)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(typingBorderColor, lineWidth: hasAnswered ? 2.5 : 1.5)
                    )
                    .cornerRadius(14)
                    .disabled(hasAnswered)
                    .submitLabel(.done)
                    .onSubmit {
                        if !hasAnswered && !typingInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            checkTypingAnswer()
                        }
                    }
                    .offset(x: shakeOffset)

                clozeFeedback(item: item)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func clozeTextBlock(item: QuizSessionManager.QuizItem, before: String, after: String) -> some View {
        let wordColor: Color = {
            if !hasAnswered { return themeStore.accentBlue }
            if isCorrect && !isAlmostCorrect { return themeStore.mainText }
            if isAlmostCorrect { return themeStore.mainText }
            return themeStore.mainText
        }()

        return HStack(spacing: 0) {
            Text(before)
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(themeStore.mainText)

            if clozeRevealed {
                Text(" \(item.word) ")
                    .font(.custom("Poppins-Bold", size: 18))
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
                // Show first letter as a hint
                clozeBlank(for: item)
            }

            Text(after)
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(themeStore.mainText)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: clozeRevealed)
    }

    private func clozeBlank(for item: QuizSessionManager.QuizItem) -> some View {
        let firstLetter = item.word.first.map { String($0) } ?? ""
        let blanks = String(repeating: "_", count: max(2, item.word.count - 1))

        return HStack(spacing: 2) {
            Text(" \(firstLetter)")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(themeStore.accentBlue)
            Text("\(blanks) ")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(themeStore.accentBlue.opacity(0.4))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(themeStore.accentBlue.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        )
    }

    private func clozeSentence(for item: QuizSessionManager.QuizItem) -> (before: String, after: String)? {
        guard let example = item.example else { return nil }
        guard let range = example.range(of: item.word, options: .caseInsensitive) else { return nil }
        let before = String(example[example.startIndex..<range.lowerBound])
        let after = String(example[range.upperBound..<example.endIndex])
        return (before, after)
    }

    // MARK: - Typing Helpers

    private var typingBorderColor: Color {
        if !hasAnswered {
            return isInputFocused ? themeStore.mainText : themeStore.dividerColor
        }
        if isAlmostCorrect { return themeStore.accentGold }
        return isCorrect ? themeStore.accentGreen : themeStore.accentRed
    }

    private func typingFeedback(expected: String) -> some View {
        Group {
            if !hasAnswered && hintShown {
                feedbackBadge(
                    icon: "lightbulb.fill",
                    text: "Hint: \(hintText)",
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && isAlmostCorrect {
                feedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Almost!",
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
            if !hasAnswered && hintShown {
                feedbackBadge(
                    icon: "lightbulb.fill",
                    text: "Hint: \(hintText)",
                    color: themeStore.accentGold
                )
            }

            if hasAnswered && isAlmostCorrect {
                feedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Almost!",
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
                .foregroundColor(themeStore.mainText)
            Text(text)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(themeStore.mainText)
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

    // MARK: - Streak Pulse & Milestones

    private func animateStreakPulse() {
        guard session.currentStreak >= 2 else { return }
        streakScale = 1.4
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            streakScale = 1.0
        }

        // Show milestone banner at key thresholds
        let streak = session.currentStreak
        if streak == 3 || streak == 5 || streak == 7 || streak == 10 || (streak > 10 && streak % 5 == 0) {
            Haptics.success()
            showStreakMilestone(streak)
        }
    }

    private func showStreakMilestone(_ streak: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            streakMilestone = streak
            streakMilestoneOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                streakMilestoneOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                streakMilestone = nil
            }
        }
    }

    private func streakMilestoneText(_ streak: Int) -> String {
        switch streak {
        case 3: return "Nice start!"
        case 5: return "On fire!"
        case 7: return "Unstoppable!"
        case 10: return "Perfect 10!"
        default: return "x\(streak) streak!"
        }
    }

    private func streakMilestoneBanner(streak: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
            Text(streakMilestoneText(streak))
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundColor(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
        )
    }

    // MARK: - Answer Checking

    private func checkTypingAnswer() {
        guard let item = session.currentItem,
              let exerciseType = session.currentExerciseType else { return }
        let trimmed = typingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let rawAnswer: String
        switch exerciseType {
        case .cloze:
            rawAnswer = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
        case .typing:
            let expected = typingReversed ? item.word : item.translation
            rawAnswer = expected.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            return
        }

        let input = trimmed.lowercased()

        // Support multiple valid answers separated by , or ;
        let variants = rawAnswer
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        var correct = false
        var almostCorrect = false

        // Check exact match against any variant
        for variant in variants {
            if input == variant {
                correct = true
                break
            }
        }

        // Check fuzzy match against any variant
        if !correct {
            for variant in variants {
                let dist = levenshteinDistance(input, variant)
                let threshold = max(1, variant.count / 4)
                if dist <= threshold {
                    almostCorrect = true
                    correct = true
                    break
                }
            }
        }

        if correct {
            // Correct or almost correct — finalize
            hasAnswered = true
            isCorrect = true
            isAlmostCorrect = almostCorrect
            Haptics.success()
            animateStreakPulse()

            if exerciseType == .cloze {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    clozeRevealed = true
                }
            }

            session.recordAnswer(correct: true)
            QuizSessionManager.applyScheduling(
                for: item.id,
                correct: true,
                isAlmostCorrect: almostCorrect,
                store: store,
                languageStore: languageStore
            )
            isInputFocused = false
        } else if !hintShown {
            // First wrong attempt — show hint, let user retry
            Haptics.error()
            triggerShake()

            let primary = variants.first ?? rawAnswer.lowercased()
            let firstChar = primary.first.map { String($0).uppercased() } ?? "?"
            let letterCount = primary.count
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                hintText = "\(firstChar)..., \(letterCount) letters"
                hintShown = true
            }
            typingInput = ""
            isInputFocused = true
        } else {
            // Second wrong attempt — finalize as incorrect
            hasAnswered = true
            isCorrect = false
            isAlmostCorrect = false
            Haptics.error()
            triggerShake()

            if exerciseType == .cloze {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    clozeRevealed = true
                }
            }

            session.recordAnswer(correct: false)
            QuizSessionManager.applyScheduling(
                for: item.id,
                correct: false,
                store: store,
                languageStore: languageStore
            )
            isInputFocused = false
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

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    QuizMixedView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
}
