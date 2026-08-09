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

    @State private var speakingAccuracy: Double? = nil

    @State private var shakeOffset: CGFloat = 0

    @State private var hintShown = false
    @State private var hintText: String = ""

    @State private var matchingPairs: [(word: String, translation: String)] = []
    @State private var matchedPairs: Set<String> = []
    @State private var selectedMatchWord: String? = nil
    @State private var selectedMatchTranslation: String? = nil
    @State private var matchingWrongPair: (String, String)? = nil
    @State private var shuffledTranslations: [String] = []
    @State private var matchingWrongAttempts: Int = 0
    private let matchingMaxAttempts: Int = 3



    @State private var streakScale: CGFloat = 1.0
    @State private var streakMilestone: Int? = nil
    @State private var streakMilestoneOpacity: Double = 0

    @State private var hasEnoughWords: Bool = true

    @State private var reward: (id: Int, text: String)? = nil
    @State private var rewardCounter = 0

    var body: some View {
        ZStack {
            if !hasEnoughWords {
                QuizNotEnoughView()
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
                    QuizProgressHeader(
                        session: session,
                        streakScale: streakScale,
                        hasAnswered: hasAnswered,
                        isCorrect: isCorrect,
                        reward: reward
                    )

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
                                wrongAttempts: matchingWrongAttempts,
                                maxAttempts: matchingMaxAttempts,
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
                                    showReward("+1")
                                    QuizSessionManager.applyScheduling(
                                        for: item.id,
                                        correct: true,
                                        store: store,
                                        languageStore: languageStore
                                    )
                                },
                                onWrongMatch: {
                                    matchingWrongAttempts += 1
                                    if matchingWrongAttempts >= matchingMaxAttempts {
                                        // Reveal all correct pairs
                                        for pair in matchingPairs {
                                            matchedPairs.insert(pair.word)
                                            matchedPairs.insert(pair.translation)
                                        }
                                        hasAnswered = true
                                        isCorrect = false
                                        session.recordAnswer(correct: false)
                                        Haptics.error()
                                        QuizSessionManager.applyScheduling(
                                            for: item.id,
                                            correct: false,
                                            store: store,
                                            languageStore: languageStore
                                        )
                                    }
                                }
                            )
                        case .sentenceBuilding:
                            EmptyView()
                        case .listening:
                            QuizListeningExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                options: options,
                                selectedOption: selectedOption,
                                shakeOffset: shakeOffset,
                                onSelect: { option in
                                    selectOption(option, item: item)
                                }
                            )
                        case .speaking:
                            QuizSpeakingExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                accuracy: speakingAccuracy,
                                shakeOffset: shakeOffset,
                                localeIdentifier: SpeechRecognizer.localeIdentifier(for: languageStore.learningLanguage),
                                onResult: { text in checkSpeakingAnswer(text, item: item) },
                                onSkip: { skipSpeaking(item: item) }
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
                QuizStreakMilestoneBanner(streak: milestone)
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
                    total: session.originalTotal
                )
                if session.correctCount == session.originalTotal && session.originalTotal > 0 {
                    NotificationCenter.default.post(name: .perfectQuizCompleted, object: nil)
                }
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
    
    private func bottomButton(exerciseType: QuizSessionManager.ExerciseType) -> some View {
        Group {
            if exerciseType == .matching && !hasAnswered {
                EmptyView()
            } else if (exerciseType == .typing || exerciseType == .cloze) && !hasAnswered {
                VStack(spacing: 10) {
                    Button {
                        checkTypingAnswer()
                    } label: {
                        Text("Check")
                            .font(themeStore.bold(16))
                            .foregroundStyle(.white)
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
                            .foregroundStyle(themeStore.secondaryText)
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
                        .foregroundStyle(.white)
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

    /// Shown after a wrong answer: the correct word–translation, an example in
    /// context, and any short explanation the word carries. Turns a mistake into
    /// a teaching moment (Duolingo-style feedback).
    private func answerExplanationPanel(item: QuizSessionManager.QuizItem) -> some View {
        let stored = store.words.first(where: { $0.id == item.id })
        let example = (stored?.example ?? item.example) ?? ""
        let note: String = {
            if let e = stored?.explanation, !e.isEmpty { return e }
            if let c = stored?.comment, !c.isEmpty { return c }
            return ""
        }()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(themeStore.accentGold)
                Text("Correct answer")
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.word)
                    .font(themeStore.bold(18))
                    .foregroundStyle(themeStore.mainText)
                Text("—")
                    .foregroundStyle(themeStore.secondaryText)
                Text(item.translation)
                    .font(themeStore.medium(16))
                    .foregroundStyle(themeStore.mainText)
            }
            .fixedSize(horizontal: false, vertical: true)
            if !example.isEmpty, example != "Add an example later" {
                Text(HighlightedExample.make(example: example, word: item.word))
                    .font(themeStore.regular(15))
                    .foregroundStyle(themeStore.mainText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !note.isEmpty {
                Text(note)
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeStore.accentGold.opacity(0.12))
        )
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
            // Remove quiz items whose words were deleted from the store
            let existingIDs = Set(store.words.map(\.id))
            let staleIDs = session.queue.filter { !existingIDs.contains($0.id) }.map(\.id)

            if !staleIDs.isEmpty {
                for staleID in staleIDs {
                    if let idx = session.queue.firstIndex(where: { $0.id == staleID }) {
                        if idx < session.currentIndex {
                            session.currentIndex = max(0, session.currentIndex - 1)
                        }
                        session.queue.remove(at: idx)
                    }
                    session.exerciseTypes.removeValue(forKey: staleID)
                    session.answerResults.removeValue(forKey: staleID)
                    session.directionMap.removeValue(forKey: staleID)
                }

                if session.queue.isEmpty || session.currentIndex >= session.queue.count {
                    session.clearSavedSession()
                    startSession()
                    return
                }
            }

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
        guard let item = session.currentItem,
              let exerciseType = session.currentExerciseType else { return }
        prepareStateForItem(item, exerciseType: exerciseType)
    }

    private func prepareStateForItem(_ item: QuizSessionManager.QuizItem, exerciseType: QuizSessionManager.ExerciseType) {
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
        speakingAccuracy = nil

        switch exerciseType {
        case .multipleChoice:
            switch direction {
            case .normal: mcReversed = false
            case .reversed: mcReversed = true
            case .mixed: mcReversed = session.directionMap[item.id] ?? Bool.random()
            }
            let distractors = session.distractors(for: item, from: store.words, reversed: mcReversed)
            let answer = mcReversed ? item.word : item.translation
            // Filter out any distractors that accidentally match the answer
            var all = distractors.filter { $0.lowercased() != answer.lowercased() } + [answer]
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
            matchingWrongAttempts = 0
            selectedMatchWord = nil
            selectedMatchTranslation = nil
            matchingWrongPair = nil
            shuffledTranslations = matchingPairs.map(\.translation).shuffled()

        case .sentenceBuilding:
            break

        case .listening:
            // Audio prompt; correct answer is the word itself, options are words.
            mcReversed = true
            let distractors = session.distractors(for: item, from: store.words, reversed: true)
            var all = distractors.filter { $0.lowercased() != item.word.lowercased() } + [item.word]
            all.shuffle()
            options = all

        case .speaking:
            break
        }
    }

    private func checkSpeakingAnswer(_ recognized: String, item: QuizSessionManager.QuizItem) {
        guard !hasAnswered else { return }
        let said = recognized.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let target = item.word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let dist = levenshteinDistance(said, target)
        let maxLen = max(target.count, said.count, 1)
        let similarity = 1.0 - Double(dist) / Double(maxLen)
        let exactish = said == target || (target.count >= 3 && said.contains(target))
        let accuracy = exactish ? 1.0 : max(0.0, similarity)
        // Grade pronunciation on a spectrum instead of pass/fail:
        //   ≥0.8 great · 0.55–0.8 close (still passes, but slower interval) · <0.55 miss.
        let passed = exactish || accuracy >= 0.55
        let almost = passed && !exactish && accuracy < 0.8

        hasAnswered = true
        isCorrect = passed
        isAlmostCorrect = almost
        speakingAccuracy = accuracy
        if passed {
            Haptics.success()
            animateStreakPulse()
            showReward("+1")
        } else {
            Haptics.error()
            triggerShake()
        }
        session.recordAnswer(correct: passed)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: passed,
            isAlmostCorrect: almost,
            store: store,
            languageStore: languageStore
        )
    }

    private func skipSpeaking(item: QuizSessionManager.QuizItem) {
        guard !hasAnswered else { return }
        Haptics.error()
        hasAnswered = true
        isCorrect = false
        triggerShake()
        session.recordAnswer(correct: false)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: false,
            store: store,
            languageStore: languageStore
        )
    }

    private func goToNext() {
        // Pre-compute the next question's state BEFORE animating the transition.
        // This avoids the flicker where the new view renders with stale values
        // (e.g. showing translation instead of word) for a split second.
        let nextIndex = session.currentIndex + 1
        if nextIndex < session.queue.count {
            let nextItem = session.queue[nextIndex]
            if let nextType = session.exerciseTypes[nextItem.id] {
                prepareStateForItem(nextItem, exerciseType: nextType)
                // Auto-play only when the user actively advances into a
                // listening question — not on tab entry or session restore,
                // where re-appearing views would otherwise replay the audio.
                if nextType == .listening {
                    Task { await AudioManager.shared.play(word: nextItem.word) }
                }
            }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            session.advance()
        }
        session.saveSession()
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
            showReward("+1")
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
            let base = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
            if let match = ClozeMatcher.find(word: item.word, in: item.example ?? ""),
               match.form.lowercased() != base.lowercased() {
                // Accept both the exact form shown in the sentence (e.g. a plural)
                // and the dictionary form the user might type instead.
                rawAnswer = "\(match.form),\(base)"
            } else {
                rawAnswer = base
            }
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
            showReward("+1")

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
                strong: !almostCorrect,
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
        let steps: [CGFloat] = [12, -10, 6, -3, 0]
        Task { @MainActor in
            for step in steps {
                withAnimation(.easeInOut(duration: 0.07)) { shakeOffset = step }
                try? await Task.sleep(for: .milliseconds(70))
            }
        }
    }

    private func showReward(_ text: String) {
        rewardCounter += 1
        let current = rewardCounter
        reward = (current, text)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.3))
            if rewardCounter == current { reward = nil }
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

}

#Preview {
    QuizMixedView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
}
