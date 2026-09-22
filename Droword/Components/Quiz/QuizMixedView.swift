import SwiftUI

struct QuizMixedView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = QuizSessionManager()

    var sessionSize: Int = 10
    var filterTag: String? = nil
    var direction: QuizDirection = .mixed
    var persistSession: Bool = true
    var presetWords: [StoredWord] = []
    var recordsLesson: Bool = false
    var onClose: (() -> Void)? = nil
    var onCompleteChange: ((Bool) -> Void)? = nil

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

    @State private var matchingPairs: [QuizSessionManager.MatchingPair] = []
    @State private var matchedPairIDs: Set<UUID> = []
    @State private var selectedMatchWordID: UUID? = nil
    @State private var selectedMatchTranslationID: UUID? = nil
    @State private var matchingWrongIDs: (UUID, UUID)? = nil
    @State private var shuffledTranslationIDs: [UUID] = []
    @State private var matchingWrongAttempts: Int = 0
    private let matchingMaxAttempts: Int = 3

    @State private var sentenceWords: [String] = []
    @State private var selectedSentenceWords: [String] = []
    @State private var correctSentenceWords: [String] = []

    @State private var streakScale: CGFloat = 1.0
    @State private var streakMilestone: Int? = nil
    @State private var streakMilestoneOpacity: Double = 0

    @State private var hasEnoughWords: Bool = true

    @State private var reward: (id: Int, text: String)? = nil
    @State private var rewardCounter = 0
    @State private var completionMoments: [StudyMoment] = []
    @State private var chatSceneTarget: ChatSceneTarget?
    @ObservedObject private var network = NetworkMonitor.shared
    @AppStorage(AppStorageKeys.showHomeChat) private var showHomeChat: Bool = true

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
                    },
                    moments: completionMoments,
                    isLesson: recordsLesson,
                    onScene: recordsLesson && FeatureGates.homeChatEnabled && showHomeChat && network.isConnected ? { openLessonScene() } : nil,
                    onClose: {
                        if let onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
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
                        case .typing, .speaking:
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
                                matchedPairIDs: $matchedPairIDs,
                                selectedMatchWordID: $selectedMatchWordID,
                                selectedMatchTranslationID: $selectedMatchTranslationID,
                                matchingWrongIDs: $matchingWrongIDs,
                                shuffledTranslationIDs: $shuffledTranslationIDs,
                                onAllMatched: {
                                    hasAnswered = true
                                    isCorrect = true
                                    session.recordAnswer(correct: true)
                                    celebrateCorrectAnswer()
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

                                        for pair in matchingPairs {
                                            matchedPairIDs.insert(pair.id)
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
                            QuizSentenceBuildingExercise(
                                item: item,
                                hasAnswered: hasAnswered,
                                isCorrect: isCorrect,
                                shakeOffset: shakeOffset,
                                sentenceWords: $sentenceWords,
                                selectedSentenceWords: $selectedSentenceWords,
                                correctSentenceWords: correctSentenceWords
                            )
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
            let usable = presetWords.isEmpty
                ? store.words.filter({ $0.translation != nil && !$0.translation!.isEmpty }).count
                : presetWords.count
            hasEnoughWords = usable >= 4
            restoreOrStartSession()
            onCompleteChange?(session.isComplete)
        }
        .fullScreenCover(item: $chatSceneTarget) { target in
            ChatSceneView(target: target)
                .environmentObject(store)
                .environmentObject(languageStore)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
        .onChange(of: session.isComplete) { _, isComplete in
            onCompleteChange?(isComplete)
            if isComplete {
                if persistSession {
                    session.clearSavedSession()
                }
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
                if persistSession {
                    session.clearSavedSession()
                }
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
            } else if (exerciseType == .typing || exerciseType == .speaking || exerciseType == .cloze) && !hasAnswered {
                VStack(spacing: 10) {
                    Button {
                        checkTypingAnswer()
                    } label: {
                        Text("Check")
                            .duo3DStyle(
                                themeStore.mainAccentColor,
                                isDisabled: typingInput.trimmingCharacters(in: .whitespaces).isEmpty
                            )
                    }
                    .buttonStyle(Duo3DButtonStyle())
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
            } else if exerciseType == .sentenceBuilding && !hasAnswered {
                VStack(spacing: 10) {
                    Button {
                        checkSentenceBuildingAnswer()
                    } label: {
                        Text("Check")
                            .duo3DStyle(
                                themeStore.mainAccentColor,
                                isDisabled: selectedSentenceWords.isEmpty
                            )
                    }
                    .buttonStyle(Duo3DButtonStyle())
                    .disabled(selectedSentenceWords.isEmpty)

                    Button {
                        skipSentenceBuilding()
                    } label: {
                        Text("Don't know")
                            .font(themeStore.medium(14))
                            .foregroundStyle(themeStore.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else if exerciseType == .listening && !hasAnswered {
                Button {
                    skipListeningAsCorrect()
                } label: {
                    Text("Can't listen")
                        .font(themeStore.medium(14))
                        .foregroundStyle(themeStore.secondaryText)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            } else if hasAnswered {
                Button {
                    Haptics.lightImpact()
                    goToNext()
                } label: {
                    Text("Continue")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

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
                Text(item.word.displayCapitalized)
                    .font(themeStore.bold(18))
                    .foregroundStyle(themeStore.mainText)
                Text("—")
                    .foregroundStyle(themeStore.secondaryText)
                Text(item.translation.displayCapitalized)
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
        if persistSession, session.restoreSession() {

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
        if persistSession {
            session.clearSavedSession()
        }
        session.maxSessionSize = presetWords.isEmpty ? sessionSize : presetWords.count
        if !presetWords.isEmpty {
            session.prepareLessonSession(
                from: presetWords,
                learningStyle: LearningProfileStore.shared.style
            )
        } else {
            session.prepareMixedSession(
                from: store.words,
                filterTag: filterTag,
                learningStyle: LearningProfileStore.shared.style,
                preferredTopics: LearningProfileStore.shared.preferredTagNames
            )
        }
        prepareCurrentQuestion()
    }

    private func prepareCurrentQuestion() {
        guard let item = session.currentItem,
              var exerciseType = session.currentExerciseType else { return }
        if exerciseType == .speaking {
            exerciseType = .typing
            session.exerciseTypes[item.id] = .typing
        }
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

        switch exerciseType {
        case .multipleChoice:
            switch direction {
            case .normal: mcReversed = false
            case .reversed: mcReversed = true
            case .mixed: mcReversed = session.directionMap[item.id] ?? Bool.random()
            }
            let distractors = session.distractors(for: item, from: store.words, reversed: mcReversed)
            let answer = mcReversed ? item.word : item.translation

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
            matchedPairIDs = []
            matchingWrongAttempts = 0
            selectedMatchWordID = nil
            selectedMatchTranslationID = nil
            matchingWrongIDs = nil
            shuffledTranslationIDs = matchingPairs.map(\.id).shuffled()

        case .sentenceBuilding:
            let source: String = {
                if let example = item.example?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !example.isEmpty {
                    return example
                }
                return item.word
            }()
            let words = source
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            correctSentenceWords = words
            sentenceWords = words.shuffled()
            selectedSentenceWords = []

        case .listening:

            mcReversed = true
            let distractors = session.distractors(for: item, from: store.words, reversed: true)
            var all = distractors.filter { $0.lowercased() != item.word.lowercased() } + [item.word]
            all.shuffle()
            options = all

        case .speaking:
            switch direction {
            case .normal: typingReversed = false
            case .reversed: typingReversed = true
            case .mixed: typingReversed = session.directionMap[item.id] ?? Bool.random()
            }
        }
    }

    private func openLessonScene() {
        guard FeatureGates.homeChatEnabled, showHomeChat, network.isConnected else { return }
        let items = session.queue.map { item in
            (
                id: item.id,
                word: item.word,
                translation: item.translation,
                correct: session.answerResults[item.id] ?? false
            )
        }
        chatSceneTarget = ChatScenePicker.fromLesson(items: items, words: store.words)
            ?? ChatScenePicker.fallback(words: store.words, learningLanguage: languageStore.learningLanguage)
    }

    private func goToNext() {

        let nextIndex = session.currentIndex + 1
        if nextIndex < session.queue.count {
            let nextItem = session.queue[nextIndex]
            if var nextType = session.exerciseTypes[nextItem.id] {
                if nextType == .speaking {
                    nextType = .typing
                    session.exerciseTypes[nextItem.id] = .typing
                }
                prepareStateForItem(nextItem, exerciseType: nextType)

                if nextType == .listening, NetworkMonitor.shared.isConnected {
                    Task { await AudioManager.shared.play(word: nextItem.word) }
                }
            }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            session.advance()
        }
        if persistSession {
            session.saveSession()
        }
        if session.isComplete {
            let results = session.queue.map { item in
                (
                    id: item.id,
                    word: item.word,
                    translation: item.translation,
                    correct: session.answerResults[item.id] ?? false
                )
            }
            completionMoments = StudyActivityStore.shared.captureSession(results: results, seedingFrom: store.words)
            if recordsLesson {
                let missed = results.filter { !$0.correct }
                StudyActivityStore.shared.rememberLessonMisses(missed.map(\.id))
                StudyActivityStore.shared.markLessonComplete(
                    correct: session.correctCount,
                    total: session.originalTotal,
                    missedWords: missed.map(\.word),
                    seedingFrom: store.words
                )
            }
            store.syncStreakToAppGroup()
        }
    }

    private func skipListeningAsCorrect() {
        guard !hasAnswered, let item = session.currentItem else { return }
        selectedOption = item.word
        hasAnswered = true
        isCorrect = true
        session.recordAnswer(correct: true)
        celebrateCorrectAnswer()
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: true,
            store: store,
            languageStore: languageStore
        )
    }

    private func selectOption(_ option: String, item: QuizSessionManager.QuizItem) {
        guard !hasAnswered else { return }
        Haptics.selection()
        selectedOption = option
        hasAnswered = true
        let correctAnswer = mcReversed ? item.word : item.translation
        isCorrect = option.lowercased() == correctAnswer.lowercased()

        session.recordAnswer(correct: isCorrect)
        if isCorrect {
            celebrateCorrectAnswer()
        } else {
            Haptics.error()
            triggerShake()
        }

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

                rawAnswer = "\(match.form),\(base)"
            } else {
                rawAnswer = base
            }
        case .typing, .speaking:
            let expected = typingReversed ? item.word : item.translation
            rawAnswer = expected.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            return
        }

        let variants = rawAnswer
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var correct = false
        var almostCorrect = false

        for variant in variants {
            if QuizAnswerMatching.isExactMatch(trimmed, expected: variant) {
                correct = true
                break
            }
        }

        if !correct {
            for variant in variants {
                if QuizAnswerMatching.isAlmostMatch(trimmed, expected: variant) {
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

            if exerciseType == .cloze {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    clozeRevealed = true
                }
            }

            session.recordAnswer(correct: true)
            celebrateCorrectAnswer()
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

            let primary = QuizAnswerMatching.normalize(variants.first ?? rawAnswer)
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

    private func checkSentenceBuildingAnswer() {
        guard !hasAnswered, let item = session.currentItem else { return }
        guard !selectedSentenceWords.isEmpty else { return }

        hasAnswered = true
        isCorrect = selectedSentenceWords == correctSentenceWords

        session.recordAnswer(correct: isCorrect)
        if isCorrect {
            celebrateCorrectAnswer()
        } else {
            Haptics.error()
            triggerShake()
        }

        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: isCorrect,
            store: store,
            languageStore: languageStore
        )
    }

    private func skipSentenceBuilding() {
        guard !hasAnswered, let item = session.currentItem else { return }
        Haptics.error()
        hasAnswered = true
        isCorrect = false
        selectedSentenceWords = correctSentenceWords
        sentenceWords = []
        triggerShake()
        session.recordAnswer(correct: false)
        QuizSessionManager.applyScheduling(
            for: item.id,
            correct: false,
            store: store,
            languageStore: languageStore
        )
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
            try? await Task.sleep(for: .seconds(0.7))
            if rewardCounter == current { reward = nil }
        }
    }

    private func celebrateCorrectAnswer() {
        Haptics.success()
        showReward("+1")
        animateStreakPulse()
    }

    private func animateStreakPulse() {
        let streak = session.currentStreak
        guard streak >= 2 else { return }
        streakScale = 1.4
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            streakScale = 1.0
        }

        if streak == 3 || streak == 5 || streak == 7 || streak == 10 || (streak > 10 && streak % 5 == 0) {
            Haptics.combo(streak: streak)
            showStreakMilestone(streak)
        } else if streak >= 3 {
            Haptics.tick()
        }
    }

    private func showStreakMilestone(_ streak: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            streakMilestone = streak
            streakMilestoneOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.28)) {
                streakMilestoneOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
