import SwiftUI

struct QuickReviewSessionView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [StoredWord] = []
    @State private var index: Int = 0
    @State private var showAnswer = false
    @State private var finished = false
    @State private var didBuildQueue = false
    @State private var reviewedCount = 0
    @State private var isPlaying = false
    @State private var isHoldingAudio = false
    @State private var holdStartedAt: Date?
    @State private var direction: Direction = .recognition
    @State private var hintText: LocalizedStringKey?
    @State private var showPremiumWall = false
    @State private var sessionResults: [(id: UUID, word: String, translation: String, correct: Bool)] = []
    @State private var doneMoments: [StudyMoment] = []
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    private let maxCards = 12

    private enum Direction { case recognition, production }

    private var remaining: Int { max(0, queue.count - index) }
    private var progress: Double {
        guard !queue.isEmpty else { return 0 }
        return Double(min(index, queue.count)) / Double(queue.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if !didBuildQueue {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if finished || queue.isEmpty {
                    donePane
                } else if index < queue.count {
                    sessionPane
                }
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
        }
        .onAppear(perform: buildQueue)
        .onChange(of: finished) { _, isFinished in
            guard isFinished, reviewedCount > 0 else { return }
            doneMoments = StudyActivityStore.shared.captureSession(results: sessionResults, seedingFrom: store.words)
            store.syncStreakToAppGroup()
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(finished ? String(localized: "Session done") : String(localized: "2-min session"))
                    .font(themeStore.bold(16))
                    .foregroundStyle(themeStore.mainText)
                if !finished, !queue.isEmpty {
                    Text("\(remaining) left")
                        .font(themeStore.regular(12))
                        .foregroundStyle(themeStore.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.bottom, 8)

            if !finished {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(themeStore.dividerColor.opacity(0.35))
                        Capsule()
                            .fill(themeStore.mainAccentColor)
                            .frame(width: max(8, geo.size.width * progress))
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
    }

    private var sessionPane: some View {
        let word = queue[index]
        let secondaryText = themeStore.mainText.opacity(0.8)
        let showWordHeader = direction == .recognition || showAnswer

        return VStack(spacing: 16) {
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 8) {
                if let tag = word.tag, !tag.isEmpty {
                    Text(LocalizedStringKey(tag))
                        .font(themeStore.bold(12))
                        .foregroundStyle(themeStore.isMonochrome ? themeStore.mainText : themeStore.colorForTag(tag))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(themeStore.colorForTag(tag).opacity(themeStore.isMonochrome ? 0.18 : 0.2))
                        )
                        .padding(.bottom, 2)
                }

                if showWordHeader {
                    HStack(alignment: .top, spacing: 8) {
                        Text(word.word)
                            .font(themeStore.medium(24))
                            .tracking(-0.2)
                            .foregroundStyle(themeStore.mainText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        soundWaves(for: word)
                    }
                    .frame(maxWidth: .infinity)

                    if let transcription = word.transcription, !transcription.isEmpty {
                        Text("[\(transcription)]")
                            .font(themeStore.regular(14))
                            .foregroundStyle(secondaryText)
                    }

                    if !word.type.isEmpty {
                        Text(word.type.capitalized)
                            .font(themeStore.regular(14))
                            .foregroundStyle(secondaryText)
                            .padding(.bottom, 2)
                    }
                } else {
                    Text(word.translation ?? "—")
                        .font(themeStore.medium(24))
                        .tracking(-0.2)
                        .foregroundStyle(themeStore.mainText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(String(localized: "Say the word"))
                        .font(themeStore.regular(14))
                        .foregroundStyle(secondaryText)
                }

                if showAnswer {
                    if direction == .recognition {
                        Text(word.translation ?? "—")
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.mainText)
                    } else if let translation = word.translation, !translation.isEmpty {
                        Text(translation)
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.mainText)
                    }

                    if let example = word.example, !example.isEmpty {
                        Text(example)
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.mainText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if word.examples.count > 1 {
                        ForEach(Array(word.examples.dropFirst().enumerated()), id: \.offset) { _, extra in
                            Text(extra)
                                .font(themeStore.regular(16))
                                .foregroundStyle(themeStore.mainText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let explanation = word.explanation, !explanation.isEmpty {
                        Text(explanation)
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.mainText)
                    }

                    if let breakdown = word.breakdown, !breakdown.isEmpty {
                        Text(breakdown)
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.mainText)
                    }

                    if !word.collocations.isEmpty {
                        sessionListBlock(title: "Common phrases", items: word.collocations)
                    }
                    if !word.synonyms.isEmpty {
                        sessionListBlock(title: "Synonyms", items: word.synonyms)
                    }
                    if !word.antonyms.isEmpty {
                        sessionListBlock(title: "Opposites", items: word.antonyms)
                    }

                    if let mnemonic = word.mnemonic, !mnemonic.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(themeStore.accentGold)
                                .padding(.top, 1)
                            Text(mnemonic)
                                .font(themeStore.regular(14))
                                .foregroundStyle(secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 6)
                    }

                    if let comment = word.comment, !comment.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 14))
                                .foregroundStyle(themeStore.secondaryText.opacity(0.7))
                                .padding(.top, 2)
                            Text(comment)
                                .font(themeStore.regular(16))
                                .foregroundStyle(themeStore.secondaryText)
                        }
                        .padding(.top, 4)
                    }
                } else {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { showAnswer = true }
                    } label: {
                        Text("Show answer")
                            .duo3DStyle(themeStore.mainAccentColor)
                    }
                    .buttonStyle(Duo3DButtonStyle())
                    .padding(.top, 8)
                }

                if let hintText {
                    Text(hintText)
                        .font(themeStore.medium(13))
                        .foregroundStyle(themeStore.accentGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous))
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
            .padding(.horizontal, 20)

            Spacer()

            if showAnswer {
                HStack(spacing: 8) {
                    gradeButton("Hard", color: themeStore.accentRed) {
                        Haptics.warning()
                        grade(.hard)
                    }
                    gradeButton("Good", color: themeStore.mainAccentColor) {
                        Haptics.buttonPress()
                        grade(.good)
                    }
                    gradeButton("Easy", color: themeStore.accentGreen) {
                        Haptics.success()
                        grade(.easy)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: showAnswer)
        .id(word.id)
    }

    @ViewBuilder
    private func soundWaves(for word: StoredWord) -> some View {
        SoundWavesView(isPlaying: isPlaying)
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isHoldingAudio else { return }
                        holdStartedAt = Date()
                        isHoldingAudio = true
                        TTSPlayer.beginHold(
                            word: word.word,
                            isPremium: isPremium,
                            onNeedsPremium: { showPremiumWall = true },
                            onPlayingChanged: { isPlaying = $0 }
                        )
                    }
                    .onEnded { _ in
                        guard isHoldingAudio else { return }
                        let elapsed = Date().timeIntervalSince(holdStartedAt ?? Date())
                        isHoldingAudio = false
                        holdStartedAt = nil
                        TTSPlayer.endHold(onPlayingChanged: { isPlaying = $0 })
                        if elapsed < 0.22 {
                            playAudio(for: word)
                        }
                    }
            )
            .accessibilityLabel(Text("Pronunciation"))
            .padding(.top, 2)
    }

    private func sessionListBlock(title: LocalizedStringKey, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(themeStore.medium(13))
                .foregroundStyle(themeStore.secondaryText)
            Text(items.joined(separator: "  ·  "))
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.mainText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private var donePane: some View {
        let copy = DuoChaosCopy.quickSessionDone(count: reviewedCount)
        return VStack(spacing: 20) {
            Spacer()
            Text(copy.title)
                .zoomerTitle(34)
                .environmentObject(themeStore)
            Text(copy.subtitle)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ForEach(doneMoments) { moment in
                VStack(spacing: 4) {
                    Text(moment.word)
                        .font(themeStore.medium(16))
                        .foregroundStyle(themeStore.mainText)
                    Text(moment.landed
                         ? String(localized: "Yesterday this was hard. Today you got it.")
                         : String(localized: "Keep this one close. It will come back tomorrow."))
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
            }

            Button {
                Haptics.buttonPress()
                dismiss()
            } label: {
                Text("Done")
                    .duo3DStyle(themeStore.mainAccentColor)
            }
            .buttonStyle(Duo3DButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()
        }
    }

    private func gradeButton(_ title: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .duo3DStyle(color)
        }
        .buttonStyle(Duo3DButtonStyle())
    }

    private func buildQueue() {
        let now = Date()
        let due = store.words
            .filter { WordDue.isDue(introduced: $0.introduced, dueDate: $0.dueDate, now: now) }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        queue = Array(due.prefix(maxCards))
        index = 0
        reviewedCount = 0
        finished = queue.isEmpty
        didBuildQueue = true
        if !queue.isEmpty {
            pickDirection()
        }
    }

    private func pickDirection() {
        guard index < queue.count else { return }
        let reps = queue[index].repetitions
        direction = reps < 1 ? .recognition : (Bool.random() ? .production : .recognition)
    }

    private func grade(_ quality: SRSScheduler.ReviewGrade) {
        guard index < queue.count else { return }
        let word = queue[index]

        languageStore.recordLearningSample(quality.learningSample)

        let result = SRSScheduler.scheduleReview(
            state: SchedulingState(
                easeFactor: word.easeFactor,
                intervalDays: word.intervalDays,
                repetitions: word.repetitions,
                lapses: word.lapses
            ),
            grade: quality
        )

        store.updateScheduling(
            for: word.id,
            easeFactor: result.state.easeFactor,
            intervalDays: result.state.intervalDays,
            repetitions: result.state.repetitions,
            lapses: result.state.lapses,
            dueDate: result.dueDate
        )

        if quality == .hard, let after = result.reinsertAfterCards {
            var copy = queue
            copy.remove(at: index)
            let insertAt = min(index + after, copy.count)
            copy.insert(word, at: insertAt)
            queue = copy
            showAnswer = false
            hintText = nil
            pickDirection()
            return
        }

        reviewedCount += 1
        sessionResults.append((
            id: word.id,
            word: word.word,
            translation: word.translation ?? "",
            correct: quality != .hard
        ))

        if quality != .hard {
            let days = SRSScheduler.previewReviewIntervalDays(
                state: SchedulingState(
                    easeFactor: word.easeFactor,
                    intervalDays: word.intervalDays,
                    repetitions: word.repetitions,
                    lapses: word.lapses
                ),
                grade: quality
            )
            hintText = days == 1
                ? "Next review tomorrow"
                : "Next review in \(days) days"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (hintText == nil ? 0.15 : 0.7)) {
            withAnimation(.easeInOut(duration: 0.2)) {
                hintText = nil
                showAnswer = false
                index += 1
                if index >= queue.count {
                    finished = true
                } else {
                    pickDirection()
                }
            }
        }
    }

    private func playAudio(for word: StoredWord) {
        TTSPlayer.play(
            word: word.word,
            isPremium: isPremium,
            onNeedsPremium: { showPremiumWall = true },
            onPlayingChanged: { isPlaying = $0 }
        )
    }
}
