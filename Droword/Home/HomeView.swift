import SwiftUI
import AVFoundation

struct HomeView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @EnvironmentObject private var suggested: SuggestedWordsStore
    @EnvironmentObject private var studyTimeTracker: StudyTimeTracker
    @StateObject private var challengeManager = DailyChallengeManager.shared
    @ObservedObject private var learningProfile = LearningProfileStore.shared
    @ObservedObject private var studyActivity = StudyActivityStore.shared

    @State private var showAddWordView = false
    @State private var sharedWord: String = ""
    @State private var selectedTab: Tab = .home
    @State private var activeMilestone: MilestoneType?
    @AppStorage(AppStorageKeys.lastCelebratedWordCount) private var lastCelebratedWordCount: Int = 0
    @AppStorage(AppStorageKeys.lastCelebratedDailyGoal) private var lastCelebratedDailyGoalDate: String = ""
    @AppStorage(AppStorageKeys.hasSeenSuggestedIntro) private var hasSeenSuggestedIntro: Bool = false
    @AppStorage(AppStorageKeys.seasonalEffectsEnabled) private var seasonalEffectsEnabled: Bool = false
    @AppStorage(AppStorageKeys.seasonalAnimationEnabled) private var seasonalAnimationEnabled: Bool = true
    @AppStorage(AppStorageKeys.hasSeenCoachMarks) private var hasSeenCoachMarks: Bool = false
    @AppStorage(AppStorageKeys.hasSeenFirstWords) private var hasSeenFirstWords: Bool = false
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasEverAddedWord) private var hasEverAddedWord: Bool = false
    @AppStorage(AppStorageKeys.hasSeenStreakPaywall) private var hasSeenStreakPaywall: Bool = false
    @AppStorage(AppStorageKeys.hasSeenPerfectQuizPaywall) private var hasSeenPerfectQuizPaywall: Bool = false
    @AppStorage(AppStorageKeys.lastCelebratedStreak) private var lastCelebratedStreak: Int = 0
    @AppStorage(AppStorageKeys.showWordPacks) private var showWordPacksSection: Bool = true
    @AppStorage(AppStorageKeys.showDailyChallenges) private var showDailyChallengesSection: Bool = false
    @AppStorage(AppStorageKeys.homeQuietedV1) private var homeQuietedV1: Bool = false

    @State private var showFirstWords = false
    @State private var showSuggestedIntro = false
    @State private var showMotivationalPaywall = false
    @State private var pendingStreakPaywall = false
    @State private var showChallenges = false
    @State private var showWordPacks = false
    @State private var showPremiumFromLimit = false
    @State private var showCoachMarks = false
    @State private var enrichmentToast: String?
    @State private var copiedToast = false
    @State private var cachedRecentWords: [StoredWord] = []
    @State private var cachedDueWordsCount: Int = 0
    @State private var cachedNextReviewInfo: (count: Int, date: Date)? = nil
    @State private var showDailyLesson = false
    @State private var showStory = false
    @State private var showStreakCalendar = false
    @State private var showLearningVibe = false
    @State private var chatSceneTarget: ChatSceneTarget?
    @State private var recentCardAppeared: Set<UUID> = []
    @State private var lastSuggestionTodayCount: Int?
    @State private var reviewTimerDismissed = false

    enum Tab: String, CaseIterable, Identifiable {
        case home
        case practice
        case add
        case list

        var id: String { rawValue }
    }

    private let coachMarkSteps: [CoachMarkStep] = [
        CoachMarkStep(
            title: "Add words",
            message: "Tap + to add a word. I translate it, find examples, and make a card.",
            icon: "plus.circle.fill"
        ),
        CoachMarkStep(
            title: "Today's lesson",
            message: "One short session on Home. Due words and your vibe go in there.",
            icon: "bolt.fill"
        ),
        CoachMarkStep(
            title: "Practice",
            message: "Want another round? Practice is extra. Home is just the lesson.",
            icon: "brain.head.profile"
        ),
        CoachMarkStep(
            title: "Your week",
            message: "The fire and the week dots are the same streak. Study keeps it alive.",
            icon: "flame.fill"
        ),
    ]

    private var dueWordsCount: Int { cachedDueWordsCount }

    private var nextReviewInfo: (count: Int, date: Date)? { cachedNextReviewInfo }

    var body: some View {
        homeOverlays(homeEvents(homeCovers(tabRoot)))
    }

    private var tabRoot: some View {
        TabView(selection: $selectedTab) {
            mainContent
                .tabItem { Label("", systemImage: "house") }
                .tag(Tab.home)

            DictionaryView()
                .tabItem { Label("", systemImage: "rectangle.portrait.on.rectangle.portrait") }
                .tag(Tab.list)

            PracticeView()
                .tabItem { Label("", systemImage: "lightbulb") }
                .tag(Tab.practice)

            Color.clear
                .tabItem { Label("", systemImage: "plus.circle") }
                .tag(Tab.add)
        }
        .tint(themeStore.tabTint)
        .background(themeStore.appBg.ignoresSafeArea())
        .environmentObject(suggested)
        .onChange(of: selectedTab) { _, newValue in
            NotificationCenter.default.post(name: .dismissReactionPicker, object: nil)
            if newValue == .add {
                Haptics.addWordTap()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    showAddWordView = true
                }
                selectedTab = .home
            }
        }
    }

    private func homeCovers<Content: View>(_ content: Content) -> some View {
        content
        .fullScreenCover(isPresented: $showAddWordView, onDismiss: {
            sharedWord = ""
            checkSuggestionTrigger()
        }) {
            AddWordView(initialWord: sharedWord, store: store)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
                .transaction { $0.disablesAnimations = true }
        }
        .fullScreenCover(isPresented: $showChallenges) {
            DailyChallengeDetailView(manager: challengeManager)
                .environmentObject(themeStore)
                .environmentObject(store)
                .environmentObject(languageStore)
                .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showWordPacks) {
            WordPacksDetailView()
                .environmentObject(themeStore)
                .environmentObject(languageStore)
                .environmentObject(store)
                .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showPremiumFromLimit) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showMotivationalPaywall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showDailyLesson, onDismiss: {
            refreshCachedWordData()
        }) {
            DailyLessonSessionView(
                plan: DailyLessonBuilder.plan(
                    words: store.words,
                    profile: learningProfile,
                    learningLanguage: languageStore.learningLanguage
                )
            )
            .environmentObject(store)
            .environmentObject(languageStore)
            .environmentObject(themeStore)
            .environmentObject(badgeStore)
            .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showLearningVibe) {
            NavigationStack {
                LearningPreferencesView(showsClose: true)
            }
            .environmentObject(themeStore)
            .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showStory) {
            StoryView()
                .environmentObject(store)
                .environmentObject(languageStore)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showStreakCalendar) {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Calendar")
                            .sheetTitle()
                        StreakCalendarView()
                        DetailedStatsView(embedded: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .background(themeStore.appBg.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CloseButton()
                    }
                }
            }
            .environmentObject(store)
            .environmentObject(languageStore)
            .environmentObject(themeStore)
            .environmentObject(studyTimeTracker)
            .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(item: $chatSceneTarget) { target in
            ChatSceneView(target: target)
                .environmentObject(store)
                .environmentObject(languageStore)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    private func homeEvents<Content: View>(_ content: Content) -> some View {
        content
        .onReceive(NotificationCenter.default.publisher(for: .sharedWordReceived)) { notification in
            if let word = notification.userInfo?["word"] as? String {
                sharedWord = word
                showAddWordView = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChatScene)) { notification in
            _ = ChatSceneLaunch.takePending()
            openChatScene(
                wordId: notification.userInfo?["wordId"] as? String,
                word: notification.userInfo?["word"] as? String
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFromWidget)) { notification in
            let host = notification.userInfo?["host"] as? String ?? "open"
            if host == "practice" {
                selectedTab = .practice
                return
            }
            selectedTab = .home
            if host == "add" {
                showAddWordView = true
            } else if !StudyActivityStore.shared.isLessonDone() {
                showDailyLesson = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .copiedToClipboard)) { _ in
            Haptics.tick()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                copiedToast = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    copiedToast = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .wordsEnriched)) { notification in
            guard let words = notification.userInfo?["words"] as? [String], !words.isEmpty else { return }
            let message = words.count == 1
                ? String(localized: "\"\(words[0])\" updated with translation")
                : String(localized: "\(words.count) words updated with translations")
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                enrichmentToast = message
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    enrichmentToast = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .perfectQuizCompleted)) { _ in
            guard !isPremium && !hasSeenPerfectQuizPaywall else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                hasSeenPerfectQuizPaywall = true
                showMotivationalPaywall = true
            }
        }
        .onChange(of: pendingStreakPaywall) { _, pending in
            guard pending else { return }
            pendingStreakPaywall = false
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                hasSeenStreakPaywall = true
                showMotivationalPaywall = true
            }
        }
        .onChange(of: suggested.suggestedWords.count) { _, newCount in
            guard newCount > 0, !hasSeenSuggestedIntro else { return }
            hasSeenSuggestedIntro = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.easeOut(duration: 0.3)) {
                    showSuggestedIntro = true
                }
            }
        }
        .onChange(of: store.words.count) { oldValue, newValue in
            guard newValue > oldValue else { return }

            let added = newValue - oldValue
            challengeManager.recordWordsAdded(count: added)
            checkSuggestionTrigger()

            let todayStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            if lastCelebratedDailyGoalDate != todayStr {
                if let goal = challengeManager.dailyGoalChallenge, goal.isCompleted {
                    lastCelebratedDailyGoalDate = todayStr
                    activeMilestone = .dailyGoal
                    badgeStore.recordDailyGoalCompletion()
                    NotificationManager.shared.scheduleDailyGoalCompletion()
                }
            }

            let wordMilestones = [10, 25, 50, 100, 200, 500]
            for m in wordMilestones {
                if newValue >= m, lastCelebratedWordCount < m {
                    lastCelebratedWordCount = m
                    activeMilestone = .wordCount(m)
                    break
                }
            }
        }
    }

    private func homeOverlays<Content: View>(_ content: Content) -> some View {
        content
        .overlay {
            if let milestone = activeMilestone {
                MilestoneCelebrationView(
                    milestone: milestone,
                    wordsCount: store.words.count,
                    daysSinceStart: daysSinceStart
                ) {
                    let wasStreak: Bool = {
                        if case .streak = milestone { return true }
                        return false
                    }()
                    withAnimation(.easeOut(duration: 0.25)) {
                        activeMilestone = nil
                    }
                    if wasStreak && !isPremium && !hasSeenStreakPaywall {
                        pendingStreakPaywall = true
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }

            if showSuggestedIntro {
                SuggestedWordsIntroView {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showSuggestedIntro = false
                    }
                }
                .transition(.opacity)
                .zIndex(101)
            }

            if showCoachMarks {
                CoachMarkView(steps: coachMarkSteps) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCoachMarks = false
                        hasSeenCoachMarks = true
                    }
                }
                .transition(.opacity)
                .zIndex(102)
            }

            if showFirstWords {
                FirstWordsView {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showFirstWords = false
                        hasSeenFirstWords = true
                    }
                }
                .transition(.opacity)
                .zIndex(103)
            }
        }
        .overlay(alignment: .top) {
            if let toast = enrichmentToast {
                BannerToastView(type: .success, message: toast)
                    .zIndex(200)
            }
            if copiedToast {
                BannerToastView(type: .success, message: String(localized: "Copied"), duration: 1.5)
                    .zIndex(201)
            }
        }
    }

    private var mainContent: some View {
        ScrollViewReader { _ in
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                ProfileHeaderView()
                    .padding(.bottom, 16)

                DailyLessonCard(
                    plan: DailyLessonBuilder.plan(
                        words: store.words,
                        profile: learningProfile,
                        learningLanguage: languageStore.learningLanguage
                    ),
                    onStart: {
                        showDailyLesson = true
                    },
                    onEditVibe: {
                        showLearningVibe = true
                    }
                )
                .padding(.horizontal, 20)

                HomeStreakStrip(
                    onOpenCalendar: {
                        Haptics.softTap()
                        showStreakCalendar = true
                    }
                )
                .padding(.horizontal, 20)

                if store.words.filter({ $0.translation?.isEmpty == false }).count >= 3 {
                    ReadingStoryCard {
                        Haptics.buttonPress()
                        showStory = true
                    }
                    .padding(.horizontal, 20)
                }

                if store.words.count < 8, showWordPacksSection {
                    let packsReady = WordPacksHome.availableCount(
                        learning: languageStore.learningLanguage,
                        native: languageStore.nativeLanguage
                    )
                    if packsReady > 0 {
                        Button {
                            Haptics.buttonPress()
                            showWordPacks = true
                        } label: {
                            WordPacksButton(availableCount: packsReady)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityLabel(Text("Word Packs"))
                        .accessibilityHint(Text("\(packsReady) packs ready"))
                        .padding(.horizontal, 20)
                    }
                }

                if showDailyChallengesSection {
                    Button {
                        Haptics.buttonPress()
                        showChallenges = true
                    } label: {
                        DailyChallengeButton(manager: challengeManager)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel(Text("Daily Challenges"))
                    .accessibilityHint(Text("\(challengeManager.completedCount) of \(challengeManager.challenges.count) completed"))
                    .padding(.horizontal, 20)
                }

                if dueWordsCount == 0, !reviewTimerDismissed, let info = nextReviewInfo {
                    HomeNextReviewCard(count: info.count, date: info.date) {
                        reviewTimerDismissed = true
                    }
                }

                if dueWordsCount == 0 {
                    SuggestedWordsView()
                        .environmentObject(suggested)
                        .padding(.horizontal, 20)
                }

                if !cachedRecentWords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently added")
                            .zoomerTitle(22)
                            .environmentObject(themeStore)
                            .padding(.horizontal, 36)

                        if !isPremium && !DailyLimitsManager.canTranslate {
                            enrichmentLimitBanner
                                .padding(.horizontal, 20)
                        }

                        ForEach(Array(cachedRecentWords.enumerated()), id: \.element.id) { index, word in
                            WordCardView(
                                word: word.word,
                                translation: word.translation,
                                type: word.type,
                                example: word.example,
                                transcription: word.transcription,
                                comment: word.comment,
                                explanation: word.explanation,
                                breakdown: word.breakdown,
                                tag: word.tag,
                                examples: word.examples,
                                collocations: word.collocations,
                                synonyms: word.synonyms,
                                antonyms: word.antonyms,
                                mnemonic: word.mnemonic,
                                reaction: word.reaction
                            ) {
                                store.remove(word)
                            } onReaction: { emoji in
                                store.setReaction(for: word.id, reaction: emoji)
                            }
                            .padding(.horizontal, 20)
                            .opacity(recentCardAppeared.contains(word.id) ? 1 : 0)
                            .offset(y: recentCardAppeared.contains(word.id) ? 0 : 20)
                            .onAppear {
                                let delay = Double(index) * 0.08
                                _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
                                    recentCardAppeared.insert(word.id)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                } else {
                    VStack(spacing: 14) {
                        Button {
                            Haptics.buttonPress()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showAddWordView = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text(DuoChaosCopy.homeEmpty(hasWords: hasEverAddedWord).cta)
                            }
                            .duo3DStyle(themeStore.mainAccentColor)
                        }
                        .buttonStyle(Duo3DButtonStyle())
                        .padding(.horizontal, 20)

                        Text(DuoChaosCopy.homeEmpty(hasWords: hasEverAddedWord).subtitle)
                            .font(themeStore.regular(14))
                            .foregroundStyle(themeStore.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.bottom, 20)
            .iPadContentWidth()
        }
        .background {
            ZStack {
                themeStore.appBg
                if seasonalEffectsEnabled {
                    SeasonalOverlayView(animated: seasonalAnimationEnabled)
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            if !homeQuietedV1 {
                showDailyChallengesSection = false
                homeQuietedV1 = true
            }
            refreshCachedWordData()
            challengeManager.refreshIfNeeded()
            if let pending = ChatSceneLaunch.takePending() {
                openChatScene(wordId: pending.wordId, word: pending.word)
            }

            if !hasSeenFirstWords && store.words.isEmpty,
               StarterWordBank.words(learning: languageStore.learningLanguage, native: languageStore.nativeLanguage) != nil {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.6))
                    withAnimation(.easeOut(duration: 0.3)) {
                        showFirstWords = true
                    }
                }
            } else if !hasSeenCoachMarks && hasSeenFirstWords {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.8))
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCoachMarks = true
                    }
                }
            }

            let currentStreak = WordsStore.computeCurrentStreak(from: store.words)
            let streakMilestones = [7, 30, 100, 365]
            for m in streakMilestones {
                if currentStreak >= m, lastCelebratedStreak < m {
                    lastCelebratedStreak = m
                    activeMilestone = .streak(m)
                    break
                }
            }
        }
        .onChange(of: store.revision) { _, _ in refreshCachedWordData() }
        }
    }

    private var enrichmentLimitBanner: some View {
        HStack(spacing: 14) {
            StatusBannerView(
                icon: "clock",
                iconColor: themeStore.mainAccentColor,
                title: "Daily limit reached",
                subtitle: "New words won't get translations until tomorrow. Upgrade to Pro for unlimited."
            )
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(themeStore.secondaryText.opacity(0.45))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        .onTapGesture {
            Haptics.softTap()
            showPremiumFromLimit = true
        }
        .accessibilityLabel(Text("Daily limit reached"))
        .accessibilityHint(Text("Tap to upgrade to Pro"))
    }

    private var daysSinceStart: Int {
        let str = UserDefaults.standard.string(forKey: AppStorageKeys.firstUseDate) ?? ""
        guard let start = DateFormatting.dayFormatter.date(from: str) else { return 1 }
        return max(1, Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 1)
    }

    private func openChatScene(wordId: String?, word: String?) {
        guard let target = ChatScenePicker.from(
            wordId: wordId,
            word: word,
            words: store.words,
            learningLanguage: languageStore.learningLanguage
        ) else { return }
        selectedTab = .home
        chatSceneTarget = target
    }

    private func refreshCachedWordData() {
        cachedRecentWords = Array(store.words.sorted(by: { $0.dateAdded > $1.dateAdded }).prefix(3))

        let now = Date()
        cachedDueWordsCount = store.words.filter { w in
            WordDue.isDue(introduced: w.introduced, dueDate: w.dueDate, now: now)
        }.count

        let upcoming = store.words.compactMap { w -> Date? in
            guard WordDue.isUpcoming(introduced: w.introduced, dueDate: w.dueDate, now: now) else { return nil }
            return w.dueDate
        }.sorted()
        if let earliest = upcoming.first {
            let windowEnd = earliest.addingTimeInterval(3600)
            let count = upcoming.filter { $0 <= windowEnd }.count
            cachedNextReviewInfo = (count, earliest)
        } else {
            cachedNextReviewInfo = nil
        }
    }

    private func checkSuggestionTrigger() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let todayCount = store.words.filter { $0.dateAdded >= startOfDay }.count
        guard todayCount > 0, todayCount % 5 == 0, todayCount != lastSuggestionTodayCount else { return }
        lastSuggestionTodayCount = todayCount

        let premium = UserDefaults.standard.bool(forKey: AppStorageKeys.isPremium)
        if premium || DailyLimitsManager.canFetchSuggestions {
            if !premium { DailyLimitsManager.recordSuggestionFetch() }
            Task {
                await suggested.fetchSuggestions(basedOn: store.words, languageStore: languageStore)
            }
        }
    }
}
