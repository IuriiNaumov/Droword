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

    @State private var clozeRevealed = false

    @State private var shakeOffset: CGFloat = 0

    @State private var hintShown = false
    @State private var hintText: String = ""

    @State private var matchingPairs: [(word: String, translation: String)] = []
    @State private var matchedPairs: Set<String> = []
    @State private var selectedMatchWord: String? = nil
    @State private var selectedMatchTranslation: String? = nil
    @State private var matchingWrongPair: (String, String)? = nil
    @State private var shuffledTranslations: [String] = []

    @State private var sentenceWords: [String] = []
    @State private var selectedSentenceWords: [String] = []
    @State private var correctSentenceWords: [String] = []

    @State private var streakScale: CGFloat = 1.0
    @State private var streakMilestone: Int? = nil
    @State private var streakMilestoneOpacity: Double = 0

    @State private var hasEnoughWords: Bool = true

    var body: some View {
        ZStack {
            if !hasEnoughWords {
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

                    ZStack {
                        switch exerciseType {
                        case .multipleChoice:
                            QuizMultipleChoiceExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                isReversed: mcReversed,
                                options: options,
                                selectedOption: selectedOption,
                                shakeOffset: shakeOffset,
                                onSelect: { option in
                                    selectOption(option, item: item)
                                }
                            )
                        case .typing:
                            QuizTypingExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                isAlmostCorrect: isAlmostCorrect,
                                isReversed: typingReversed,
                                shakeOffset: shakeOffset,
                                hintShown: hintShown,
                                hintText: hintText,
                                typingInput: $typingInput,
                                isInputFocused: $isInputFocused,
                                onSubmit: { checkTypingAnswer() }
                            )
                        case .cloze:
                            QuizClozeExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                isAlmostCorrect: isAlmostCorrect,
                                clozeRevealed: clozeRevealed,
                                shakeOffset: shakeOffset,
                                hintShown: hintShown,
                                hintText: hintText,
                                typingInput: $typingInput,
                                isInputFocused: $isInputFocused,
                                onSubmit: { checkTypingAnswer() }
                            )
                        case .matching:
                            QuizMatchingExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                matchingPairs: $matchingPairs,
                                matchedPairs: $matchedPairs,
                                selectedMatchWord: $selectedMatchWord,
                                selectedMatchTranslation: $selectedMatchTranslation,
                                matchingWrongPair: $matchingWrongPair,
                                shuffledTranslations: $shuffledTranslations,
                                onAllMatched: {
                                    hasAnswered = true
                                    isCorrect = true
                                    session.recordAnswer(correct: true)
                                    animateStreakPulse()
                                    QuizSessionManager.applyScheduling(
                                        for: item.id,
                                        correct: true,
                                        store: store,
                                        languageStore: languageStore
                                    )
                                },
                                onWrongMatch: {}
                            )
                        case .sentenceBuilding:
                            QuizSentenceBuildingExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                shakeOffset: shakeOffset,
                                sentenceWords: $sentenceWords,
                                selectedSentenceWords: $selectedSentenceWords,
                                correctSentenceWords: correctSentenceWords
                            )
                        }
                    }
                    .id(session.currentIndex)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 30)),
                        removal: .opacity.combined(with: .offset(x: -30))
                    ))

                    Spacer(minLength: 0)

                    bottomButton(exerciseType: exerciseType)
                }
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
        .onAppear {
            hasEnoughWords = store.words.filter({ $0.translation != nil && !$0.translation!.isEmpty }).count >= 4
            restoreOrStartSession()
        }
        .onChange(of: session.isComplete) { _, isComplete in
            if isComplete {
                session.clearSavedSession()
                badgeStore.recordQuizCompletion()
                DailyChallengeManager.shared.recordQuizCompleted(
                    score: session.correctCount,
                    total: session.total
                )
            }
        }
        .onTapGesture { isInputFocused = false }
        .onChange(of: store.words.count) { _, _ in
            let usable = store.words.filter { $0.translation != nil && !$0.translation!.isEmpty }.count
            hasEnoughWords = usable >= 4
            if usable < 4 {
                session.clearSavedSession()
                session.queue = []
                session.currentIndex = 0
                session.isComplete = false
                session.answeredCount = 0
                session.orderedResults = []
                session.correctCount = 0
                return
            }

            let existingIDs = Set(store.words.map(\.id))
            let removedIDs = session.queue.filter { !existingIDs.contains($0.id) }.map(\.id)
            guard !removedIDs.isEmpty else { return }

            for removedID in removedIDs {
                if let idx = session.queue.firstIndex(where: { $0.id == removedID }) {
                    if idx < session.currentIndex {
                        session.currentIndex = max(0, session.currentIndex - 1)
                    } else if idx == session.currentIndex {
                        hasAnswered = false
                        isCorrect = false
                    }
                    session.queue.remove(at: idx)
                }
                session.exerciseTypes.removeValue(forKey: removedID)
                session.answerResults.removeValue(forKey: removedID)
                session.directionMap.removeValue(forKey: removedID)
            }

            if session.queue.isEmpty || session.currentIndex >= session.queue.count {
                session.isComplete = true
            } else {
                prepareCurrentQuestion()
            }
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(min(session.answeredCount + 1, session.total))/\(session.total)")
                    .font(themeStore.medium(13))
                    .foregroundColor(themeStore.secondaryText)

                Spacer()

                if session.currentStreak >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeStore.accentRed)
                        Text("\(session.currentStreak)")
                            .font(themeStore.bold(14))
                            .foregroundColor(themeStore.accentRed)
                    }
                    .scaleEffect(streakScale)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)

            segmentedProgressBar
        }
        .padding(.top, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: session.currentStreak)
    }

    private var segmentedProgressBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<session.total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(segmentColor(for: index))
                    .frame(height: 6)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.3), value: session.answeredCount)
        .animation(.easeInOut(duration: 0.3), value: hasAnswered)
    }

    private func segmentColor(for index: Int) -> Color {
        if index < session.answeredCount {
            if index < session.orderedResults.count {
                return session.orderedResults[index] ? themeStore.accentGreen : themeStore.accentRed
            }
            return themeStore.accentGreen
        }
        if index == session.answeredCount {
            if hasAnswered {
                return isCorrect ? themeStore.accentGreen : themeStore.accentRed
            }
            return themeStore.secondaryText.opacity(0.35)
        }
        return themeStore.dividerColor.opacity(0.4)
    }

    private func bottomButton(exerciseType: QuizSessionManager.ExerciseType) -> some View {
        Group {
            if exerciseType == .matching && !hasAnswered {
                EmptyView()
            } else if exerciseType == .sentenceBuilding && !hasAnswered {
                VStack(spacing: 10) {
                    Button {
                        checkSentenceAnswer()
                    } label: {
                        Text("Check")
                            .font(themeStore.bold(16))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedSentenceWords.isEmpty
                                        ? themeStore.secondaryText.opacity(0.3)
                                        : themeStore.mainAccentColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedSentenceWords.isEmpty)

                    Button {
                        skipQuestion()
                    } label: {
                        Text("Don't know")
                            .font(themeStore.medium(14))
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
                            .font(themeStore.bold(16))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(typingInput.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? themeStore.secondaryText.opacity(0.3)
                                        : themeStore.mainAccentColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(typingInput.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        skipQuestion()
                    } label: {
                        Text(hintShown ? LocalizedStringKey("Show answer") : LocalizedStringKey("Don't know"))
                            .font(themeStore.medium(14))
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
                        .font(themeStore.bold(16))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themeStore.mainAccentColor)
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

    private func restoreOrStartSession() {
        if session.restoreSession() {
            prepareCurrentQuestion()
        } else {
            startSession()
        }
    }

    private func startSession() {
        session.clearSavedSession()
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
            selectedMatchTranslation = nil
            matchingWrongPair = nil
            shuffledTranslations = matchingPairs.map(\.translation).shuffled()

        case .sentenceBuilding:
            if let example = item.example {
                correctSentenceWords = example.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                sentenceWords = correctSentenceWords.shuffled()
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
        hasAnswered = false
        isCorrect = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            session.advance()
        }
        session.saveSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            prepareCurrentQuestion()
        }
    }

    private func selectOption(_ option: String, item: QuizSessionManager.QuizItem) {
        guard !hasAnswered else { return }
        Haptics.selection()
        selectedOption = option
        hasAnswered = true
        let correctAnswer = mcReversed ? item.word : item.translation
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

        let variants = rawAnswer
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        var correct = false
        var almostCorrect = false

        for variant in variants {
            if input == variant {
                correct = true
                break
            }
        }

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
            Haptics.error()
            triggerShake()

            let primary = variants.first ?? rawAnswer.lowercased()
            let firstChar = primary.first.map { String($0).uppercased() } ?? "?"
            let letterCount = primary.count
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                hintText = String(localized: "\(firstChar)..., \(letterCount) letters")
                hintShown = true
            }
            typingInput = ""
            isInputFocused = true
        } else {
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

    private func triggerShake() {
        withAnimation(.default) { shakeOffset = 12 }
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

    private func animateStreakPulse() {
        guard session.currentStreak >= 2 else { return }
        streakScale = 1.4
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            streakScale = 1.0
        }

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
        case 3: return String(localized: "Nice start!")
        case 5: return String(localized: "On fire!")
        case 7: return String(localized: "Unstoppable!")
        case 10: return String(localized: "Perfect 10!")
        default: return String(localized: "x\(streak) streak!")
        }
    }

    private func streakMilestoneBanner(streak: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundColor(themeStore.accentRed)
            Text(streakMilestoneText(streak))
                .font(themeStore.bold(16))
                .foregroundColor(themeStore.mainText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeStore.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
                )
        )
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
