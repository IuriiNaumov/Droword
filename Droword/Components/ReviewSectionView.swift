import SwiftUI

struct ReviewSectionView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var learningQueue: [WordCard] = []
    @State private var currentIndex: Int = 0
    @State private var showTranslation: Bool = false
    @State private var isPlaying: Bool = false
    @State private var showPremiumWall: Bool = false
    @AppStorage(AppStorageKeys.reviewAllCaughtUp) private var allCaughtUp: Bool = false
    @AppStorage(AppStorageKeys.reviewDismissed) private var dismissed: Bool = false
    @AppStorage(AppStorageKeys.reviewSessionDate) private var sessionDateRaw: Double = 0
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasSeenReviewPaywall) private var hasSeenReviewPaywall: Bool = false
    @State private var showPaywallFromReview: Bool = false
    @State private var nextReviewText: LocalizedStringKey? = nil

    private var totalDue: Int { learningQueue.count }
    private var remaining: Int { max(0, learningQueue.count - currentIndex) }

    /// Which way the current card quizzes the user.
    /// `recognition`: show the word, recall the meaning (easier).
    /// `production`: show the meaning, recall the word itself (harder, deeper).
    private enum ReviewDirection { case recognition, production }
    @State private var currentDirection: ReviewDirection = .recognition

    private var displayedCardID: UUID? {
        currentIndex < learningQueue.count ? learningQueue[currentIndex].id : nil
    }

    /// Picks the quiz direction for the card now on screen. The first-ever review
    /// of a word is always recognition (you must recognise before you can
    /// produce); afterwards production is mixed in ~50% to train active recall.
    private func pickDirection() {
        guard let id = displayedCardID else { return }
        let reps = store.words.first(where: { $0.id == id })?.repetitions ?? 0
        currentDirection = reps < 1 ? .recognition : (Bool.random() ? .production : .recognition)
    }

    var body: some View {
        Group {
        if allCaughtUp && !dismissed && totalDue > 0 {
            allCaughtUpBanner
                .transition(.opacity)
        } else if !allCaughtUp && currentIndex < learningQueue.count {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Review")
                        .font(themeStore.bold(24))
                        .foregroundStyle(themeStore.mainText)

                    Text("\(remaining) words")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)

                    Spacer()
                }

                reviewCard
                    .id(learningQueue[currentIndex].id)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: currentIndex)
            }
        }
        }
        .onAppear { refreshDueState() }
        .onChange(of: store.words.count) { handleWordsChanged() }
        .onChange(of: displayedCardID) { pickDirection() }
        .task {
            // Self-heal while the view is on screen: pull words whose dueDate
            // crosses `now` (time-based) without relying on navigation or edits.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                if Task.isCancelled { break }
                refreshDueState()
            }
        }
    }


    private var card: WordCard { learningQueue[currentIndex] }

    private var backgroundColor: Color {
        themeStore.cardBg
    }



    private var primaryText: Color {
        themeStore.mainText
    }
    private var secondaryText: Color {
        themeStore.mainText.opacity(0.8)
    }

    private var audioButton: some View {
        Button(action: { Haptics.selection(); playAudio() }) {
            SoundWavesView(isPlaying: isPlaying)
                .frame(width: 24, height: 24)
                .tint(primaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Play pronunciation"))
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tag = card.tag, !tag.isEmpty {
                Text(LocalizedStringKey(tag))
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.colorForTag(tag))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(themeStore.colorForTag(tag), lineWidth: 1)
                    )
            }

            // PROMPT — recognition shows the word, production shows the meaning.
            if currentDirection == .recognition {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(card.word)
                        .font(themeStore.bold(24))
                        .foregroundStyle(primaryText)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    audioButton
                }

                HStack(spacing: 8) {
                    if let tr = card.transcription, !tr.isEmpty {
                        Text(tr)
                            .font(themeStore.regular(14))
                            .foregroundStyle(secondaryText)
                    }
                    Text(card.partOfSpeech.capitalized)
                        .font(themeStore.regular(14))
                        .foregroundStyle(secondaryText)
                }
            } else {
                Text(card.translation)
                    .font(themeStore.bold(24))
                    .foregroundStyle(primaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 12, weight: .medium))
                    Text("Recall the word")
                        .font(themeStore.regular(14))
                    if !card.partOfSpeech.isEmpty {
                        Text("·")
                            .font(themeStore.regular(14))
                        Text(card.partOfSpeech.capitalized)
                            .font(themeStore.regular(14))
                    }
                }
                .foregroundStyle(secondaryText)
            }

            if showTranslation {
                VStack(alignment: .leading, spacing: 10) {
                    // The answer: meaning for recognition, the word itself for production.
                    if currentDirection == .recognition {
                        Text(card.translation)
                            .font(themeStore.medium(17))
                            .foregroundStyle(primaryText)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(card.word)
                                .font(themeStore.bold(22))
                                .foregroundStyle(primaryText)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            audioButton
                        }
                        if let tr = card.transcription, !tr.isEmpty {
                            Text(tr)
                                .font(themeStore.regular(14))
                                .foregroundStyle(secondaryText)
                        }
                    }

                    if let comment = card.comment, !comment.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 13))
                                .foregroundStyle(secondaryText.opacity(0.7))
                                .padding(.top, 1)
                            Text(comment)
                                .font(themeStore.regular(14))
                                .foregroundStyle(secondaryText)
                        }
                    }

                    if card.example != "Add an example later" {
                        Text(highlightedExample(example: card.example, target: card.word))
                            .font(themeStore.regular(15))
                            .foregroundStyle(primaryText)
                    }

                    if let explanation = card.explanation, !explanation.isEmpty {
                        Text(explanation)
                            .font(themeStore.regular(14))
                            .foregroundStyle(secondaryText)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showTranslation = true }
                    Haptics.lightImpact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.system(size: 14))
                        Text(currentDirection == .production ? "Show word" : "Show translation")
                            .font(themeStore.medium(15))
                    }
                    .foregroundStyle(primaryText.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(primaryText.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }

            if let text = nextReviewText {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .medium))
                    Text(text)
                        .font(themeStore.medium(13))
                }
                .foregroundStyle(themeStore.accentGreen)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(spacing: 8) {
                Button {
                    Haptics.warning()
                    scheduleNext(for: card, quality: .hard)
                    advanceToNext(didReinsert: true)
                } label: {
                    Text("Hard")
                        .font(themeStore.bold(15))
                        .foregroundStyle(.white)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themeStore.accentRed)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.lightImpact()
                    let ivl = computeNextInterval(for: card, quality: .good)
                    scheduleNext(for: card, quality: .good)
                    showNextReviewHint(days: ivl)
                } label: {
                    Text("Good")
                        .font(themeStore.bold(15))
                        .foregroundStyle(.white)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themeStore.accentBlue)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.success()
                    let ivl = computeNextInterval(for: card, quality: .easy)
                    scheduleNext(for: card, quality: .easy)
                    showNextReviewHint(days: ivl)
                } label: {
                    Text("Easy")
                        .font(themeStore.bold(15))
                        .foregroundStyle(.white)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themeStore.accentGreen)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : backgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 20))
        .cardDepth(cornerRadius: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Review card: \(card.word)"))
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }


    @Environment(\.colorScheme) private var colorScheme

    private var iconCircleFill: Color {
        themeStore.iconCircleFill(colorScheme: colorScheme)
    }

    private var allCaughtUpBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconCircleFill)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeStore.accentGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("All caught up!")
                        .font(themeStore.bold(16))
                        .foregroundStyle(themeStore.mainText)
                    Text("You reviewed \(totalDue) words.\nNew reviews will appear when it's time to practice.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        dismissed = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeStore.accentBlue)
                }
                .buttonStyle(.plain)
            }

            if !isPremium && !hasSeenReviewPaywall {
                Button {
                    hasSeenReviewPaywall = true
                    showPaywallFromReview = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Unlock unlimited reviews")
                                .font(themeStore.medium(14))
                            Text("Try Pro free for 7 days")
                                .font(themeStore.regular(12))
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(darkerShade(of: themeStore.accentGold, by: 0.5))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(themeStore.accentGold.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .onAppear { hasSeenReviewPaywall = true }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
        .fullScreenCover(isPresented: $showPaywallFromReview) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    /// Reconciles the on-screen review state with the ground truth in `store.words`
    /// (any word with `dueDate <= now`). This is the SAME source Home's due counter
    /// uses, so the CTA card and this section can never disagree.
    private func refreshDueState() {
        // An active, not-yet-finished session is preserved; we only append words
        // that have newly become due so we don't discard the user's progress.
        if !allCaughtUp && currentIndex < learningQueue.count {
            pullNewlyDue()
            return
        }

        // Otherwise (empty queue, finished/exhausted session, or "all caught up"),
        // rebuild from scratch whenever real due words exist. This clears the trap
        // where a stale non-empty queue blocked rebuilding.
        let now = Date()
        let hasDue = store.words.contains { w in
            guard w.introduced, let due = w.dueDate else { return false }
            return due <= now
        }
        if hasDue {
            prepareSession()
        }
    }

    private func prepareSession() {
        let now = Date()
        let due = store.words
            .filter { w in
                guard w.introduced, let due = w.dueDate else { return false }
                return due <= now
            }
            // Show the most overdue words first.
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        learningQueue = due.map { word in
            WordCard(
                id: word.id,
                word: word.word,
                partOfSpeech: word.type.isEmpty ? "word" : word.type,
                example: word.example ?? "Add an example later",
                translation: word.translation ?? "No translation yet",
                explanation: word.explanation,
                breakdown: word.breakdown,
                transcription: word.transcription,
                tag: word.tag,
                fromLanguage: word.fromLanguage,
                toLanguage: word.toLanguage,
                comment: word.comment
            )
        }
        currentIndex = 0
        showTranslation = false
        allCaughtUp = false
        dismissed = false
        sessionDateRaw = now.timeIntervalSince1970
    }

    private func handleWordsChanged() {
        let currentWordIDs = Set(store.words.map { $0.id })
        let queueIDs = Set(learningQueue.map { $0.id })

        // Remove deleted words
        let before = learningQueue.count
        learningQueue.removeAll { !currentWordIDs.contains($0.id) }

        // Add newly added words that are due for review
        let now = Date()
        let newDue = store.words.filter { w in
            guard w.introduced, let due = w.dueDate else { return false }
            return !queueIDs.contains(w.id) && due <= now
        }
        for word in newDue {
            learningQueue.append(
                WordCard(
                    id: word.id,
                    word: word.word,
                    partOfSpeech: word.type.isEmpty ? "word" : word.type,
                    example: word.example ?? "Add an example later",
                    translation: word.translation ?? "No translation yet",
                    explanation: word.explanation,
                    breakdown: word.breakdown,
                    transcription: word.transcription,
                    tag: word.tag,
                    fromLanguage: word.fromLanguage,
                    toLanguage: word.toLanguage,
                    comment: word.comment
                )
            )
        }

        let changed = before != learningQueue.count || !newDue.isEmpty

        // If new words appeared, reset "all caught up" state
        if !newDue.isEmpty && allCaughtUp {
            allCaughtUp = false
            dismissed = false
            showTranslation = false
            return
        }

        guard changed else { return }

        if currentIndex >= learningQueue.count {
            if allCaughtUp {
                return
            }
            allCaughtUp = true
            showTranslation = false
        } else {
            showTranslation = false
        }
    }

    private func makeCard(from word: StoredWord) -> WordCard {
        WordCard(
            id: word.id,
            word: word.word,
            partOfSpeech: word.type.isEmpty ? "word" : word.type,
            example: word.example ?? "Add an example later",
            translation: word.translation ?? "No translation yet",
            explanation: word.explanation,
            breakdown: word.breakdown,
            transcription: word.transcription,
            tag: word.tag,
            fromLanguage: word.fromLanguage,
            toLanguage: word.toLanguage,
            comment: word.comment
        )
    }

    /// Appends words that have become due since the queue was built, and clears
    /// the "all caught up" state so the review card reappears.
    private func pullNewlyDue() {
        let now = Date()
        let queueIDs = Set(learningQueue.map { $0.id })
        let newDue = store.words.filter { w in
            guard w.introduced, let due = w.dueDate else { return false }
            return !queueIDs.contains(w.id) && due <= now
        }
        guard !newDue.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            learningQueue.append(contentsOf: newDue.map(makeCard))
            if allCaughtUp {
                allCaughtUp = false
                dismissed = false
            }
            showTranslation = false
        }
    }

    private enum ReviewQuality {
        case hard, good, easy

        var q: Double {
            switch self {
            case .hard: return 3   // struggled, but not forgotten
            case .good: return 4   // recalled correctly → EF stays stable
            case .easy: return 5
            }
        }

        var scoreValue: Double {
            switch self {
            case .hard: return 0.3
            case .good: return 0.7
            case .easy: return 1.0
            }
        }
    }

    private func scheduleNext(for card: WordCard, quality: ReviewQuality) {
        guard let w = store.words.first(where: { $0.id == card.id }) else { return }

        var ef = max(1.3, w.easeFactor)
        var reps = w.repetitions
        var ivl = w.intervalDays
        let lapses = w.lapses

        let q = quality.q

        let alpha = 0.06
        let prev = languageStore.learningScore
        languageStore.learningScore = max(0.0, min(1.0, prev * (1 - alpha) + quality.scoreValue * alpha))

        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        ef = min(3.0, max(1.3, ef))

        let now = Date()
        let cal = Calendar.current

        if quality == .hard {
            // Struggled but not forgotten: keep the card in today's session and
            // re-drill it shortly, WITHOUT wiping accumulated progress
            // (repetitions / interval / lapses are preserved). Only the ease
            // factor takes the usual small SM-2 penalty.
            reinsert(card, after: 2)
            let due = cal.date(byAdding: .minute, value: 10, to: now)
            store.updateScheduling(for: card.id,
                                   easeFactor: ef,
                                   intervalDays: ivl,
                                   repetitions: reps,
                                   lapses: lapses,
                                   dueDate: due)
        } else {
            // Good / Easy: advance the schedule.
            reps += 1
            if reps == 1 {
                ivl = quality == .easy ? 2 : 1
            } else if reps == 2 {
                ivl = quality == .easy ? 8 : 6
            } else {
                let multiplier = quality == .easy ? ef * 1.3 : ef
                ivl = max(1, Int(round(Double(ivl) * multiplier)))
            }
            let due = cal.date(byAdding: .day, value: ivl, to: now)
            store.updateScheduling(for: card.id,
                                   easeFactor: ef,
                                   intervalDays: ivl,
                                   repetitions: reps,
                                   lapses: lapses,
                                   dueDate: due)
        }
    }

    private func computeNextInterval(for card: WordCard, quality: ReviewQuality) -> Int {
        guard let w = store.words.first(where: { $0.id == card.id }) else { return 1 }
        var ef = max(1.3, w.easeFactor)
        let q = quality.q
        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        ef = min(3.0, max(1.3, ef))
        let reps = w.repetitions + 1
        if reps == 1 { return quality == .easy ? 2 : 1 }
        else if reps == 2 { return quality == .easy ? 8 : 6 }
        else {
            let multiplier = quality == .easy ? ef * 1.3 : ef
            return max(1, Int(round(Double(w.intervalDays) * multiplier)))
        }
    }

    private func showNextReviewHint(days: Int) {
        let text: LocalizedStringKey = days == 1
            ? "Next review tomorrow"
            : "Next review in \(days) days"
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            nextReviewText = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                nextReviewText = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                advanceToNext(didReinsert: false)
            }
        }
    }

    private func reinsert(_ card: WordCard, after positions: Int) {
        guard currentIndex < learningQueue.count else { return }
        learningQueue.remove(at: currentIndex)
        // Ensure at least 1 card gap so user doesn't see the same card immediately
        let remaining = learningQueue.count - currentIndex
        let effectivePositions = remaining > 0 ? max(positions, 1) : 0
        let newIndex = min(currentIndex + effectivePositions, learningQueue.count)
        learningQueue.insert(card, at: newIndex)
    }

    private func advanceToNext(didReinsert: Bool) {
        showTranslation = false
        nextReviewText = nil
        DailyChallengeManager.shared.recordWordsReviewed(count: 1)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if !didReinsert {
                currentIndex += 1
            }
            if currentIndex >= learningQueue.count {
                allCaughtUp = true
                sessionDateRaw = Date().timeIntervalSince1970
                Haptics.success()
            }
        }
    }


    private func playAudio() {
        TTSPlayer.play(
            word: card.word,
            isPremium: isPremium,
            onNeedsPremium: { showPremiumWall = true },
            onPlayingChanged: { isPlaying = $0 }
        )
    }

    private func highlightedExample(example: String, target: String) -> AttributedString {
        var attr = AttributedString(example)
        let lower = example.lowercased()
        let lowerTarget = target.lowercased()
        guard let range = lower.range(of: lowerTarget) else { return attr }

        let startOK: Bool = {
            if range.lowerBound == lower.startIndex { return true }
            let prev = lower.index(before: range.lowerBound)
            return !lower[prev].isLetter && !lower[prev].isNumber
        }()
        let endOK: Bool = {
            if range.upperBound == lower.endIndex { return true }
            let next = range.upperBound
            return !lower[next].isLetter && !lower[next].isNumber
        }()

        if startOK && endOK,
           let attrStart = AttributedString.Index(range.lowerBound, within: attr),
           let attrEnd = AttributedString.Index(range.upperBound, within: attr) {
            attr[attrStart..<attrEnd].foregroundColor = Color(red: 1.0, green: 0.549, blue: 0.259)
            attr[attrStart..<attrEnd].font = .custom("Poppins-Bold", size: 15)
        }
        return attr
    }
}


