import SwiftUI
import UIKit

struct ReadingStoryCard: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 14) {
                Image(systemName: "book.pages")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(themeStore.mainText)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading")
                        .font(themeStore.bold(16))
                        .foregroundStyle(themeStore.mainText)
                    Text(DuoChaosCopy.readingSubtitle())
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
                Spacer()
                DisclosureChevron()
            }
            .padding(DesignSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("Reading practice"))
    }
}

struct StoryView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    @State private var story: StoryResult?
    @State private var isLoading = false
    @State private var loadingLine = DuoChaosCopy.storyWriting()
    @State private var errorMessage: String?
    @State private var errorCanRetry = true
    @State private var showTranslation = false
    @State private var showPremiumWall = false
    @State private var storySeeds: [StorySeed] = []
    @State private var selectedSeedID: UUID?
    @State private var quizChoices: [String] = []
    @State private var quizAnswers: [UUID: Bool] = [:]
    @State private var speakingID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let story {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            storyContent(story)
                                .padding(.horizontal, DesignSpacing.screenInset)
                                .padding(.top, 24)
                                .padding(.bottom, 12)
                                .frame(maxWidth: 600, alignment: .leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        storyActions
                    }
                } else if let errorMessage {
                    errorView(errorMessage)
                        .padding(.horizontal, DesignSpacing.screenInset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
        }
        .task {
            guard story == nil else { return }
            if let saved = StoryArchive.today() {
                apply(saved.result, seeds: saved.seeds, answers: saved.answers)
            } else {
                await load()
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private func storyContent(_ story: StoryResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Self.plainText(story.title, words: story.usedWords))
                .font(themeStore.bold(24))
                .foregroundStyle(themeStore.mainText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignSpacing.titleTop)
                .padding(.bottom, DesignSpacing.titleBottom)

            Text(highlightedStory(story.story, words: story.usedWords))
                .font(themeStore.regular(19))
                .foregroundStyle(themeStore.mainText)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.openURL, OpenURLAction { url in
                    guard url.scheme == "droword-word",
                          let host = url.host,
                          let id = UUID(uuidString: host) else { return .discarded }
                    selectedSeedID = id
                    Haptics.selection()
                    return .handled
                })

            if showTranslation {
                Text(Self.plainText(story.translation, words: story.usedWords))
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showTranslation = true }
                    Haptics.lightImpact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "character.book.closed")
                        Text("Show translation")
                    }
                    .font(themeStore.medium(15))
                    .foregroundStyle(themeStore.secondaryText)
                }
                .buttonStyle(.plain)
            }

            if !story.usedWords.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Slipped into the story")
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) {
                        ForEach(usedSeeds(in: story)) { seed in
                            Button {
                                selectedSeedID = seed.id
                                Haptics.selection()
                            } label: {
                                Text(seed.word)
                                    .font(themeStore.medium(14))
                                    .foregroundStyle(Color("AccentGold"))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule().fill(Color("AccentGold").opacity(selectedSeedID == seed.id ? 0.28 : 0.14))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)
            }

            if let seed = storySeeds.first(where: { $0.id == selectedSeedID }) {
                wordGloss(seed)
            }

            if let seed = pendingQuizSeed(in: story), quizChoices.count >= 2 {
                meaningQuiz(seed)
            } else if pendingQuizSeed(in: story) == nil, !quizAnswers.isEmpty {
                quizSummary(usedSeeds(in: story))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var storyActions: some View {
        VStack(spacing: DesignSpacing.buttonGap) {
            if !isPremium {
                Text("\(DailyLimitsManager.storiesRemaining) free stories left today")
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Haptics.lightImpact()
                Task { await load() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("New story")
                }
                .duo3DStyle(themeStore.mainAccentColor)
            }
            .buttonStyle(Duo3DButtonStyle())
        }
        .frame(maxWidth: 600, alignment: .leading)
        .padding(.horizontal, DesignSpacing.screenInset)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func wordGloss(_ seed: StorySeed) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(seed.word)
                    .font(themeStore.medium(16))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(seed.translation)
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                TTSPlayer.play(
                    word: seed.word,
                    isPremium: isPremium,
                    onNeedsPremium: { showPremiumWall = true },
                    onPlayingChanged: { speakingID = $0 ? seed.id : nil }
                )
            } label: {
                SoundWavesView(isPlaying: speakingID == seed.id)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Play pronunciation"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cleanCard(themeStore: themeStore, cornerRadius: themeStore.cardRadius)
    }

    private func meaningQuiz(_ seed: StorySeed) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What does this word mean?")
                .font(themeStore.medium(15))
                .foregroundStyle(themeStore.mainText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(seed.word)
                .font(themeStore.bold(18))
                .foregroundStyle(Color("AccentGold"))
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(quizChoices, id: \.self) { choice in
                Button {
                    answerQuiz(choice, seed: seed)
                } label: {
                    Text(choice)
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                .fill(themeStore.cardBg)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func quizSummary(_ seeds: [StorySeed]) -> some View {
        let remembered = seeds.filter { quizAnswers[$0.id] == true }
        let missed = seeds.filter { quizAnswers[$0.id] == false }
        return VStack(alignment: .leading, spacing: 16) {
            if !remembered.isEmpty {
                quizRows(remembered, tint: themeStore.successStrong)
            }
            if !missed.isEmpty {
                quizRows(missed, tint: themeStore.errorStrong)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func quizRows(_ seeds: [StorySeed], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(seeds) { seed in
                HStack(spacing: 8) {
                    Text(seed.word)
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                    Text(seed.translation)
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                        .fill(tint.opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func answerQuiz(_ choice: String, seed: StorySeed) {
        guard quizAnswers[seed.id] == nil else { return }
        let remembered = Self.folded(choice) == Self.folded(seed.translation)
        quizAnswers[seed.id] = remembered
        if remembered {
            Haptics.success()
        } else {
            Haptics.warning()
        }
        store.bringStoryReviewCloser(id: seed.id, remembered: remembered)
        if let story, let next = pendingQuizSeed(in: story) {
            quizChoices = choices(for: next)
        } else {
            quizChoices = []
        }
        saveProgress()
    }

    private func pendingQuizSeed(in story: StoryResult) -> StorySeed? {
        usedSeeds(in: story).first { quizAnswers[$0.id] == nil && !choices(for: $0).isEmpty }
    }

    private func choices(for seed: StorySeed) -> [String] {
        var seen = Set<String>()
        var distractors: [String] = []
        for translation in store.words.compactMap(\.translation).shuffled() {
            let key = Self.folded(translation)
            guard !translation.isEmpty, key != Self.folded(seed.translation), !seen.contains(key) else { continue }
            seen.insert(key)
            distractors.append(translation)
            if distractors.count == 2 { break }
        }
        guard !distractors.isEmpty else { return [] }
        return ([seed.translation] + distractors).shuffled()
    }

    private func usedSeeds(in story: StoryResult) -> [StorySeed] {
        storySeeds.filter { seed in
            story.usedWords.contains { Self.folded($0) == Self.folded(seed.word) }
        }
    }
    private var loadingView: some View {
        VStack(spacing: 16) {
            LoadingStagesView(
                dotSize: 14,
                bounceHeight: 10,
                spacing: 10,
                color: themeStore.mainAccentColor
            )
            .frame(height: 34)

            Text(loadingLine)
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSpacing.screenInset)
                .id(loadingLine)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadingLine = DuoChaosCopy.storyWriting()
        }
        .task(id: isLoading) {
            guard isLoading else { return }
            while !Task.isCancelled && isLoading {
                try? await Task.sleep(for: .seconds(2.4))
                guard isLoading else { break }
                withAnimation(.easeInOut(duration: 0.25)) {
                    loadingLine = DuoChaosCopy.storyWriting()
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(themeStore.secondaryText)
            Text(message)
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
            if errorCanRetry {
                Button {
                    Task { await load() }
                } label: {
                    Text(DuoChaosCopy.storyTryAgain())
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func highlightedStory(_ text: String, words: [String]) -> AttributedString {
        let cleaned = Self.plainText(text, words: words)
        let base = themeStore.uiFont(size: 19, weight: .regular)
        let bold = themeStore.uiFont(size: 19, weight: .bold)
        let highlights: [(word: String, forms: [String], link: URL?)] = usedSeeds(in: StoryResult(
            title: "",
            story: cleaned,
            translation: "",
            usedWords: words
        )).map { seed in
            (seed.word, seed.forms, URL(string: "droword-word://\(seed.id.uuidString)"))
        }
        return HighlightedExample.makeStory(
            text: cleaned,
            highlights: highlights,
            baseColor: UIColor(themeStore.mainText),
            highlightColor: UIColor(Color("AccentGold")),
            baseFont: base,
            highlightFont: bold
        )
    }

    private static func plainText(_ text: String, words: [String]) -> String {
        var result = text
        let wrappers: [(String, String)] = [
            ("***", "***"),
            ("**", "**"),
            ("*", "*"),
            ("__", "__"),
            ("_", "_"),
            ("\"", "\""),
            ("«", "»"),
            ("“", "”"),
            ("‘", "’"),
            ("'", "'"),
            ("`", "`")
        ]
        for word in words where word.count >= 2 {
            for (left, right) in wrappers {
                result = result.replacingOccurrences(
                    of: "\(left)\(word)\(right)",
                    with: word,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        result = result.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"(?<=\S)\*+"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*+(?=\S)"#, with: "", options: .regularExpression)
        for word in words where word.count >= 2 {
            for mark in ["\"", "«", "»", "“", "”", "`"] {
                result = result.replacingOccurrences(
                    of: "\(mark)\(word)",
                    with: word,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
                result = result.replacingOccurrences(
                    of: "\(word)\(mark)",
                    with: word,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        return result
    }

    private func load() async {
        let seeds = StoryWordPicker.candidates(
            from: store.words,
            learningLanguage: languageStore.learningLanguage,
            preferredTags: LearningProfileStore.shared.preferredTagNames
        )
        guard seeds.count >= 3 else {
            errorCanRetry = false
            errorMessage = String(localized: "Add a few more words first to make a story.")
            return
        }
        guard isPremium || DailyLimitsManager.canGenerateStory else {
            showPremiumWall = true
            if story == nil {
                errorCanRetry = true
                errorMessage = String(localized: "You've used today's free stories. Upgrade to PRO for unlimited.")
            }
            return
        }
        errorMessage = nil
        errorCanRetry = true
        showTranslation = false
        withAnimation { isLoading = true }
        do {
            let profile = LearningProfileStore.shared
            let result = try await generateStory(
                words: seeds.map(\.word),
                languageStore: languageStore,
                goal: profile.goal.localizedTitle,
                topics: profile.topics.map(\.localizedTitle)
            )
            if !isPremium {
                DailyLimitsManager.recordStory()
            }
            StoryArchive.save(SavedReading(day: DateFormatting.todayString, result: result, seeds: seeds))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                apply(result, seeds: seeds)
            }
        } catch {
            withAnimation { isLoading = false }
            errorCanRetry = true
            let isOffline = !NetworkMonitor.shared.isConnected
                || (error as? APIError).map { if case .noConnection = $0 { return true }; return false } ?? false
            if isOffline {
                errorMessage = String(localized: "You're offline. Connect to generate a story.")
            } else {
                errorMessage = String(localized: "Couldn't create a story right now. Please try again.")
            }
        }
    }

    private func apply(_ result: StoryResult, seeds: [StorySeed], answers: [StoryQuizAnswer] = []) {
        storySeeds = seeds
        selectedSeedID = nil
        speakingID = nil
        quizAnswers = Dictionary(uniqueKeysWithValues: answers.map { ($0.id, $0.remembered) })
        story = result
        if let next = pendingQuizSeed(in: result) {
            quizChoices = choices(for: next)
        } else {
            quizChoices = []
        }
        isLoading = false
    }

    private func saveProgress() {
        guard let story else { return }
        let answers = quizAnswers.map { StoryQuizAnswer(id: $0.key, remembered: $0.value) }
        StoryArchive.save(SavedReading(
            day: DateFormatting.todayString,
            result: story,
            seeds: storySeeds,
            answers: answers
        ))
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

#Preview("Card") {
    ReadingStoryCard(onTap: {})
        .padding()
        .environmentObject(ThemeStore())
}

#Preview("Story") {
    StoryView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
}
