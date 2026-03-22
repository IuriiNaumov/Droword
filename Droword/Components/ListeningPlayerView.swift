import SwiftUI

struct ListeningPlayerView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @StateObject private var session = ListeningSessionManager()
    @State private var selectedTag: String? = nil
    @State private var showSettings = false
    @State private var hasStarted = false
    @State private var showInfoExpanded = false
    @State private var hardWordsOnly = false

    private let unifiedCornerRadius: CGFloat = 16

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { session.stop(); dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeStore.mainText)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                                    .fill(themeStore.cardBg)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Listening")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(themeStore.mainText)

                    Spacer()

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeStore.mainText)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                                    .fill(themeStore.cardBg)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if !hasStarted {
                    setupView
                } else if session.isSessionComplete {
                    listeningCompletionView
                } else {
                    playerView
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ListeningSettingsSheet(settings: $session.settings) {
                session.settings.save()
            }
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(themeStore.mainText.opacity(0.3))

            VStack(spacing: 8) {
                Text("Audio flashcards")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(themeStore.mainText)

                Text("Listen to words with pauses for active recall. Perfect for walks, driving, or cooking.")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Filter by tag")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(themeStore.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                            .fill(themeStore.cardBg)
                    )
                    .padding(.horizontal, 20)

                TagsView(
                    selectedTag: $selectedTag,
                    compact: true,
                    showManagementControls: false
                )
                .padding(.horizontal, 20)
            }

            // Hard words filter
            HStack {
                Text("Hard words only")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(themeStore.mainText)
                Spacer()
                Toggle("", isOn: $hardWordsOnly)
                    .labelsHidden()
                    .tint(themeStore.mainText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                    .fill(themeStore.cardBg)
            )
            .padding(.horizontal, 20)

            let count = filteredWords.count
            Text("\(count) \(count == 1 ? "word" : "words") selected")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(themeStore.secondaryText)

            Spacer()

            Button(action: startListening) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                    Text("Start listening")
                        .font(.custom("Poppins-Bold", size: 17))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                        .fill(filteredWords.isEmpty ? themeStore.secondaryText.opacity(0.3) : themeStore.buttonAccent)
                )
            }
            .buttonStyle(.plain)
            .disabled(filteredWords.isEmpty)
            .scaleEffect(filteredWords.isEmpty ? 1.0 : 1.02)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: filteredWords.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 0)
    }

    // MARK: - Player View

    private var playerView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Word display area
            VStack(spacing: 16) {
                if let word = session.currentWord {
                    VStack(spacing: 12) {

                        // Sound waves during audio playback
                        if session.isAudioPlaying {
                            SoundWavesView(isPlaying: session.isAudioPlaying)
                                .frame(height: 24)
                                .transition(.opacity)
                        }

                        // Word text
                        Text(word.word)
                            .font(.custom("Poppins-Bold", size: 30))
                            .foregroundColor(themeStore.mainText)
                            .multilineTextAlignment(.center)
                            .animation(.easeInOut(duration: 0.3), value: word.id)

                        // Transcription below word
                        if session.currentPhase == .word || session.currentPhase == .pause,
                           let transcription = word.transcription, !transcription.isEmpty {
                            Text(transcription)
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(themeStore.secondaryText)
                                .transition(.opacity)
                        }

                        // Tap to reveal during pause
                        if session.currentPhase == .pause && !session.translationRevealed {
                            Button(action: {
                                Haptics.lightImpact()
                                session.revealTranslation()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 14))
                                    Text("Tap to reveal")
                                        .font(.custom("Poppins-Medium", size: 15))
                                }
                                .foregroundColor(themeStore.secondaryText)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                                        .fill(themeStore.cardBg)
                                )
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale))
                        }

                        // Translation when revealed or in later phases
                        if session.currentPhase == .translation
                            || session.currentPhase == .gap
                            || session.currentPhase == .example
                            || (session.currentPhase == .pause && session.translationRevealed) {
                            if let translation = word.translation {
                                Text(translation)
                                    .font(.custom("Poppins-Regular", size: 20))
                                    .foregroundColor(themeStore.secondaryText)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }

                        // Collapsible details (explanation + breakdown)
                        if word.explanation != nil || word.breakdown != nil {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showInfoExpanded.toggle()
                                }
                                Haptics.lightImpact()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: showInfoExpanded ? "chevron.up" : "info.circle")
                                        .font(.system(size: 13))
                                    Text(showInfoExpanded ? "Hide details" : "Details")
                                        .font(.custom("Poppins-Medium", size: 13))
                                }
                                .foregroundColor(themeStore.secondaryText.opacity(0.7))
                            }
                            .buttonStyle(.plain)

                            if showInfoExpanded {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let explanation = word.explanation, !explanation.isEmpty {
                                        Text(explanation)
                                            .font(.custom("Poppins-Regular", size: 14))
                                            .foregroundColor(themeStore.secondaryText)
                                            .multilineTextAlignment(.leading)
                                    }
                                    if let breakdown = word.breakdown, !breakdown.isEmpty {
                                        Text(breakdown)
                                            .font(.custom("Poppins-Regular", size: 14))
                                            .foregroundColor(themeStore.secondaryText.opacity(0.8))
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: session.currentPhase)
                    .animation(.easeInOut(duration: 0.3), value: session.translationRevealed)
                    .animation(.easeInOut(duration: 0.3), value: session.isAudioPlaying)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            Spacer()

            // Controls area
            VStack(spacing: 20) {
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: Double(session.currentWordIndex), total: max(1, Double(session.totalWords)))
                        .tint(themeStore.mainText)

                    Text("\(min(session.currentWordIndex + 1, max(1, session.totalWords))) / \(session.totalWords)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.secondaryText)
                }

                // Sleep timer
                if session.sleepTimerRemaining > 0 {
                    let mins = session.sleepTimerRemaining / 60
                    let secs = session.sleepTimerRemaining % 60
                    Text(String(format: "Sleep: %d:%02d", mins, secs))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(themeStore.secondaryText)
                }

                // Playback speed selector
                HStack(spacing: 0) {
                    ForEach([("0.75x", Float(0.75)), ("1x", Float(1.0)), ("1.25x", Float(1.25))], id: \.0) { label, speed in
                        let isSelected = session.playbackSpeed == speed
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                session.playbackSpeed = speed
                                AudioManager.shared.overrideRate = speed
                            }
                            Haptics.selection()
                        } label: {
                            Text(label)
                                .font(.custom("Poppins-Medium", size: 12))
                                .foregroundColor(isSelected ? .white : themeStore.mainText)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: unifiedCornerRadius - 4)
                                        .fill(isSelected ? themeStore.buttonAccent : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                        .fill(themeStore.cardBg.opacity(0.5))
                )
                .padding(.horizontal, 20)

                // Repeat + I Know This buttons
                HStack(spacing: 16) {
                    Button(action: {
                        session.replayCurrentWord()
                        Haptics.lightImpact()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18))
                            Text("Repeat")
                                .font(.custom("Poppins-Regular", size: 11))
                        }
                        .foregroundColor(themeStore.mainText.opacity(0.7))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        session.markCurrentWordKnown()
                        Haptics.success()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 18))
                            Text("I know this")
                                .font(.custom("Poppins-Regular", size: 11))
                        }
                        .foregroundColor(themeStore.accentGreen)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)

                // Main playback controls
                HStack(spacing: 40) {
                    Button(action: { session.skipBackward(); Haptics.lightImpact() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeStore.mainText)
                    }
                    .buttonStyle(.plain)

                    Button(action: { session.togglePause(); Haptics.mediumImpact() }) {
                        Image(systemName: session.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(themeStore.mainText)
                    }
                    .buttonStyle(.plain)

                    Button(action: { session.skipForward(); Haptics.lightImpact() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeStore.mainText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(themeStore.dividerColor, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .onChange(of: session.currentWord?.id) {
            showInfoExpanded = false
        }
    }

    // MARK: - Completion View

    private var listeningCompletionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(themeStore.accentGreen)

            Text("Session Complete!")
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(themeStore.mainText)

            VStack(spacing: 12) {
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(session.wordsListened)")
                            .font(.custom("Poppins-Bold", size: 32))
                            .foregroundColor(themeStore.mainText)
                        Text("Words")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(themeStore.secondaryText)
                    }

                    VStack(spacing: 4) {
                        Text(sessionDurationString)
                            .font(.custom("Poppins-Bold", size: 32))
                            .foregroundColor(themeStore.mainText)
                        Text("Duration")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(themeStore.secondaryText)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                    .fill(themeStore.cardBg)
            )

            Spacer()

            Button(action: { Haptics.mediumImpact(); dismiss() }) {
                Text("Done")
                    .font(.custom("Poppins-Bold", size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                            .fill(themeStore.buttonAccent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private var sessionDurationString: String {
        guard let start = session.sessionStartDate else { return "0:00" }
        let elapsed = Int(Date().timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var filteredWords: [StoredWord] {
        var result = store.words
        if let tag = selectedTag, !tag.isEmpty {
            result = result.filter {
                ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(tag) == .orderedSame
            }
        }
        if hardWordsOnly {
            result = result.filter { $0.easeFactor < 2.0 }
        }
        return result
    }

    private func startListening() {
        Haptics.mediumImpact()
        hasStarted = true
        session.settings.hardWordsOnly = hardWordsOnly

        session.onWordCompleted = { word in
            QuizSessionManager.applyScheduling(
                for: word.id,
                correct: true,
                store: store,
                languageStore: languageStore
            )
        }
        session.onWordMarkedKnown = { word in
            QuizSessionManager.applyScheduling(
                for: word.id,
                correct: true,
                store: store,
                languageStore: languageStore
            )
        }

        session.startSession(words: store.words, filterTag: selectedTag)
    }
}

#Preview {
    ListeningPlayerView()
        .environmentObject(WordsStore())
}
