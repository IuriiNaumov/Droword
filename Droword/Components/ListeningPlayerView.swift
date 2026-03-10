import SwiftUI

struct ListeningPlayerView: View {
    @EnvironmentObject private var store: WordsStore
    @StateObject private var session = ListeningSessionManager()
    @State private var selectedTag: String? = nil
    @State private var showSettings = false
    @State private var hasStarted = false

    private let unifiedCornerRadius: CGFloat = 16

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { session.stop(); dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.mainBlack)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                                    .fill(Color.cardBackground)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Listening")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.mainBlack)

                    Spacer()

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.mainBlack)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                                    .fill(Color.cardBackground)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if !hasStarted {
                    setupView
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

    private var setupView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(.mainBlack.opacity(0.3))

            VStack(spacing: 8) {
                Text("Audio flashcards")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.mainBlack)

                Text("Listen to words with pauses for active recall. Perfect for walks, driving, or cooking.")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.mainGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Filter by tag")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.mainGrey)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal, 20)

                TagsView(
                    selectedTag: $selectedTag,
                    compact: true,
                    showManagementControls: false
                )
                .padding(.horizontal, 20)
            }

            let count = filteredWords.count
            Text("\(count) \(count == 1 ? "word" : "words") selected")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.mainGrey)

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
                        .fill(filteredWords.isEmpty ? Color.mainGrey.opacity(0.3) : Color.accentBlue)
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

    private var playerView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {

                if let word = session.currentWord {
                    VStack(spacing: 12) {
                        Text(word.word)
                            .font(.custom("Poppins-Bold", size: 30))
                            .foregroundColor(.mainBlack)
                            .multilineTextAlignment(.center)
                            .animation(.easeInOut(duration: 0.3), value: word.id)

                        if session.currentPhase == .translation || session.currentPhase == .gap {
                            if let translation = word.translation {
                                Text(translation)
                                    .font(.custom("Poppins-Regular", size: 20))
                                    .foregroundColor(.mainGrey)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: session.currentPhase)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    ProgressView(value: Double(session.currentWordIndex), total: max(1, Double(session.totalWords)))
                        .tint(.accentBlue)

                    Text("\(min(session.currentWordIndex + 1, max(1, session.totalWords))) / \(session.totalWords)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.mainGrey)
                }

                if session.sleepTimerRemaining > 0 {
                    let mins = session.sleepTimerRemaining / 60
                    let secs = session.sleepTimerRemaining % 60
                    Text(String(format: "Sleep: %d:%02d", mins, secs))
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.mainGrey)
                }

                HStack(spacing: 40) {
                    Button(action: { session.skipBackward(); Haptics.lightImpact() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.mainBlack)
                    }
                    .buttonStyle(.plain)

                    Button(action: { session.togglePause(); Haptics.mediumImpact() }) {
                        Image(systemName: session.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.accentBlue)
                    }
                    .buttonStyle(.plain)

                    Button(action: { session.skipForward(); Haptics.lightImpact() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.mainBlack)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.divider, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .onChange(of: session.isPlaying) { _, playing in
            if !playing && hasStarted {
            }
        }
    }

    private var filteredWords: [StoredWord] {
        if let tag = selectedTag, !tag.isEmpty {
            return store.words.filter {
                ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(tag) == .orderedSame
            }
        }
        return store.words
    }

    private func startListening() {
        Haptics.mediumImpact()
        hasStarted = true
        session.startSession(words: store.words, filterTag: selectedTag)
    }
}

struct ListeningSettingsSheet: View {
    @Binding var settings: ListeningSettings
    var onSave: () -> Void

    private let unifiedCornerRadius: CGFloat = 16

    @Environment(\.dismiss) private var dismiss

    private let pauseOptions: [(String, Double)] = [
        ("1s", 1),
        ("2s", 2),
        ("3s", 3),
        ("5s", 5),
        ("7s", 7),
    ]

    private let repeatOptions: [(String, Int)] = [
        ("1x", 1),
        ("2x", 2),
        ("3x", 3),
    ]

    private let sleepOptions: [(String, Int)] = [
        ("Off", 0),
        ("10m", 10),
        ("15m", 15),
        ("20m", 20),
        ("30m", 30),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    settingSection(title: "Recall pause") {
                        segmentedPicker(
                            options: pauseOptions,
                            selected: settings.pauseDuration,
                            onSelect: { settings.pauseDuration = $0 }
                        )
                    }

                    settingSection(title: "Word order") {
                        segmentedPicker(
                            options: [
                                ("Foreign first", false),
                                ("Native first", true),
                            ],
                            selected: settings.nativeFirst,
                            onSelect: { settings.nativeFirst = $0 }
                        )
                    }

                    settingRow(title: "Example sentences", isOn: $settings.includeExamples)

                    settingRow(title: "Shuffle order", isOn: $settings.shuffle)

                    settingSection(title: "Repetitions per word") {
                        segmentedPicker(
                            options: repeatOptions,
                            selected: settings.repeatCount,
                            onSelect: { settings.repeatCount = $0 }
                        )
                    }

                    settingSection(title: "Sleep timer") {
                        segmentedPicker(
                            options: sleepOptions,
                            selected: settings.sleepTimerMinutes,
                            onSelect: { settings.sleepTimerMinutes = $0 }
                        )
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                    .font(.custom("Poppins-Medium", size: 16))
                }
            }
        }
    }

    @ViewBuilder
    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.mainBlack)
            content()
        }
    }

    private func settingRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.mainBlack)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.accentBlue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private func segmentedPicker<T: Equatable>(
        options: [(String, T)],
        selected: T,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                let isSelected = opt.1 == selected
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onSelect(opt.1)
                    }
                    Haptics.selection()
                } label: {
                    Text(opt.0)
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(isSelected ? .white : .mainBlack)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: unifiedCornerRadius - 4)
                                .fill(isSelected ? Color.accentBlue : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    ListeningPlayerView()
        .environmentObject(WordsStore())
}
