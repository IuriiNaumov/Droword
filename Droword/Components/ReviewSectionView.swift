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
    @State private var allCaughtUp: Bool = false
    @AppStorage("isPremium") private var isPremium: Bool = false
    @AppStorage("hasSeenReviewPaywall") private var hasSeenReviewPaywall: Bool = false
    @State private var showPaywallFromReview: Bool = false

    private var totalDue: Int { learningQueue.count }
    private var remaining: Int { max(0, learningQueue.count - currentIndex) }

    var body: some View {
        Group {
        if allCaughtUp {
            allCaughtUpBanner
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            allCaughtUp = false
                        }
                    }
                }
        } else if currentIndex < learningQueue.count {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Review")
                        .font(themeStore.bold(24))
                        .foregroundColor(themeStore.mainText)

                    Text("\(remaining) \(remaining == 1 ? "word" : "words")")
                        .font(themeStore.regular(14))
                        .foregroundColor(themeStore.secondaryText)

                    Spacer()
                }

                reviewCard
                    .id(learningQueue[currentIndex].id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentIndex)
            }
        } else if !store.words.isEmpty {
            reviewEmptyState
        }
        }
        .onAppear { prepareSession() }
        .onChange(of: store.words.count) { prepareSession() }
    }


    private var card: WordCard { learningQueue[currentIndex] }

    private var backgroundColor: Color {
        if let tag = card.tag {
            switch tag {
            case "Chat":   return themeStore.accentBlue
            case "Travel": return themeStore.accentGreen
            case "Street": return themeStore.accentPink
            case "Movies": return themeStore.accentPurple
            case "Golden": return themeStore.goldenColor
            default:
                if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }) {
                    return themeStore.resolvedTagColor(custom.colorHex)
                }
            }
        }
        return themeStore.cardBg
    }

    private var isDarkBg: Bool { backgroundColor.reviewIsDark }
    private var hasTagColor: Bool { card.tag != nil && !card.tag!.isEmpty }

    private var primaryText: Color {
        if isDarkBg { return .white }
        if themeStore.isDuolingo && hasTagColor {
            return darkerShade(of: backgroundColor, by: 0.45)
        }
        return themeStore.mainText
    }
    private var secondaryText: Color {
        if isDarkBg { return Color.white.opacity(0.85) }
        if themeStore.isDuolingo && hasTagColor {
            return darkerShade(of: backgroundColor, by: 0.35)
        }
        return themeStore.mainText.opacity(0.8)
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let tag = card.tag, !tag.isEmpty {
                    Text(tag)
                        .font(themeStore.medium(13))
                        .foregroundColor(isDarkBg ? Color.white.opacity(0.9) : darkerShade(of: backgroundColor, by: 0.45))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(backgroundColor.opacity(isDarkBg ? 0.5 : 0.32))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(darkerShade(of: backgroundColor, by: 0.15), lineWidth: 1)
                        )
                }
                Spacer()
                Text("\(remaining) remaining")
                    .font(themeStore.regular(13))
                    .foregroundColor(secondaryText)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(card.word)
                    .font(themeStore.bold(24))
                    .foregroundColor(primaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(action: { Haptics.selection(); playAudio() }) {
                    SoundWavesView(isPlaying: isPlaying)
                        .frame(width: 24, height: 24)
                        .tint(primaryText)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                if let tr = card.transcription, !tr.isEmpty {
                    Text(tr)
                        .font(themeStore.regular(14))
                        .foregroundColor(secondaryText)
                }
                Text(card.partOfSpeech.capitalized)
                    .font(themeStore.regular(14))
                    .foregroundColor(secondaryText)
            }

            if showTranslation {
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.translation)
                        .font(themeStore.medium(17))
                        .foregroundColor(primaryText)

                    if let comment = card.comment, !comment.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 13))
                                .foregroundColor(secondaryText.opacity(0.7))
                                .padding(.top, 1)
                            Text(comment)
                                .font(themeStore.regular(14))
                                .foregroundColor(secondaryText)
                        }
                    }

                    if card.example != "Add an example later" {
                        Text(highlightedExample(example: card.example, target: card.word))
                            .font(themeStore.regular(15))
                            .foregroundColor(primaryText)
                    }

                    if let explanation = card.explanation, !explanation.isEmpty {
                        Text(explanation)
                            .font(themeStore.regular(14))
                            .foregroundColor(secondaryText)
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
                        Text("Show translation")
                            .font(themeStore.medium(15))
                    }
                    .foregroundColor(primaryText.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(primaryText.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }

            // Rating buttons
            HStack(spacing: 12) {
                Button {
                    Haptics.warning()
                    scheduleNext(for: card, isGotIt: false)
                    advanceToNext(didReinsert: true)
                } label: {
                    Text("Again")
                        .font(themeStore.bold(15))
                        .foregroundColor(darkerShade(of: themeStore.accentRed, by: 0.4))
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themeStore.accentRed)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.success()
                    scheduleNext(for: card, isGotIt: true)
                    advanceToNext(didReinsert: false)
                } label: {
                    HStack(spacing: 4) {
                        Text("Got it")
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .font(themeStore.bold(15))
                    .foregroundColor(darkerShade(of: themeStore.accentGreen, by: 0.4))
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
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }


    private var allCaughtUpBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeStore.accentGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("All caught up!")
                        .font(themeStore.bold(16))
                        .foregroundColor(themeStore.mainText)
                    Text("You reviewed \(totalDue) \(totalDue == 1 ? "word" : "words")")
                        .font(themeStore.regular(13))
                        .foregroundColor(themeStore.secondaryText)
                }
                Spacer()
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
                    .foregroundColor(darkerShade(of: themeStore.accentGold, by: 0.5))
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
                .fill(themeStore.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
                )
        )
        .fullScreenCover(isPresented: $showPaywallFromReview) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private var reviewEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review")
                .font(themeStore.bold(24))
                .foregroundColor(themeStore.mainText)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 22))
                    .foregroundColor(themeStore.accentBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your words are growing!")
                        .font(themeStore.medium(15))
                        .foregroundColor(themeStore.mainText)
                    Text("Reviews will appear here when it's time to practice.")
                        .font(themeStore.regular(13))
                        .foregroundColor(themeStore.secondaryText)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(themeStore.dividerColor, lineWidth: 1)
                    )
            )
        }
    }

    private func prepareSession() {
        let now = Date()
        let due = store.words.filter { w in
            if let due = w.dueDate { return due <= now } else { return true }
        }
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
    }

    // MARK: - SM-2 Scheduling

    private func scheduleNext(for card: WordCard, isGotIt: Bool) {
        guard let w = store.words.first(where: { $0.id == card.id }) else { return }

        var ef = max(1.3, w.easeFactor)
        var reps = w.repetitions
        var ivl = w.intervalDays
        var lapses = w.lapses

        let q: Double = isGotIt ? 4 : 1
        let quality: Double = isGotIt ? 1.0 : 0.0

        // Update learning score
        let alpha = 0.06
        let prev = languageStore.learningScore
        languageStore.learningScore = max(0.0, min(1.0, prev * (1 - alpha) + quality * alpha))

        // Update ease factor
        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        ef = max(1.3, ef)

        let now = Date()
        let cal = Calendar.current

        if !isGotIt {
            // Again: reinsert, due in 10 min
            lapses += 1
            reps = 0
            ivl = 0
            reinsert(card, after: 2)
            let due = cal.date(byAdding: .minute, value: 10, to: now)
            store.updateScheduling(for: card.id,
                                   easeFactor: ef,
                                   intervalDays: ivl,
                                   repetitions: reps,
                                   lapses: lapses,
                                   dueDate: due)
        } else {
            // Got it: schedule next interval
            reps += 1
            if reps == 1 {
                ivl = 1
            } else if reps == 2 {
                ivl = 6
            } else {
                ivl = max(1, Int(round(Double(ivl) * ef)))
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

    private func reinsert(_ card: WordCard, after positions: Int) {
        guard currentIndex < learningQueue.count else { return }
        learningQueue.remove(at: currentIndex)
        let newIndex = min(currentIndex + positions, learningQueue.count)
        learningQueue.insert(card, at: newIndex)
    }

    private func advanceToNext(didReinsert: Bool) {
        showTranslation = false
        DailyChallengeManager.shared.recordWordsReviewed(count: 1)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            // "Again" reinserts card — currentIndex already points to next card
            // "Got it" needs to increment currentIndex
            if !didReinsert {
                currentIndex += 1
            }
            if currentIndex >= learningQueue.count {
                allCaughtUp = true
                Haptics.success()
            }
        }
    }

    // MARK: - Audio

    private func playAudio() {
        guard isPremium || DailyLimitsManager.canPlayTTS else {
            showPremiumWall = true
            return
        }
        if !isPremium { DailyLimitsManager.recordTTS() }
        Task {
            isPlaying = true
            await AudioManager.shared.play(word: card.word)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation { isPlaying = false }
        }
    }

    // MARK: - Helpers

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

// Color darkness check (local to this file)
private extension Color {
    var reviewIsDark: Bool {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.2126 * r + 0.7152 * g + 0.0722 * b) < 0.5
    }
}
