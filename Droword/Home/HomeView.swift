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
    @ObservedObject private var network = NetworkMonitor.shared

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
    @AppStorage(AppStorageKeys.showHomeReading) private var showHomeReading: Bool = true
    @AppStorage(AppStorageKeys.showHomeChat) private var showHomeChat: Bool = true
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
    @State private var copiedToastToken = 0
    @State private var cachedRecentWords: [StoredWord] = []
    @State private var cachedDueWordsCount: Int = 0
    @State private var cachedNextReviewInfo: (count: Int, date: Date)? = nil
    @State private var showDailyLesson = false
    @State private var showStory = false
    @State private var showStreakCalendar = false
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

        var title: LocalizedStringKey {
            switch self {
            case .home: return "Home"
            case .list: return "Dictionary"
            case .practice: return "Practice"
            case .add: return "Add"
            }
        }

        var systemImage: String {
            switch self {
            case .home: return "house"
            case .list: return "rectangle.portrait.on.rectangle.portrait"
            case .practice: return "lightbulb"
            case .add: return "plus.circle"
            }
        }
    }

    private let coachMarkSteps: [CoachMarkStep] = CoachMarkCatalog.homeSteps

    private var dueWordsCount: Int { cachedDueWordsCount }

    private var nextReviewInfo: (count: Int, date: Date)? { cachedNextReviewInfo }

    private var dailyLessonPlan: DailyLessonPlan {
        DailyLessonBuilder.plan(
            words: store.words,
            profile: learningProfile,
            learningLanguage: languageStore.learningLanguage
        )
    }

    var body: some View {
        homeOverlays(homeEvents(homeCovers(tabRoot)))
    }

    private var tabRoot: some View {
        TabView(selection: $selectedTab) {
            mainContent
                .tabItem { Label(Tab.home.title, systemImage: Tab.home.systemImage) }
                .tag(Tab.home)

            DictionaryView()
                .tabItem { Label(Tab.list.title, systemImage: Tab.list.systemImage) }
                .tag(Tab.list)

            PracticeView(onCloseResults: { selectedTab = .home })
                .tabItem { Label(Tab.practice.title, systemImage: Tab.practice.systemImage) }
                .tag(Tab.practice)

            Color.clear
                .tabItem { Label(Tab.add.title, systemImage: Tab.add.systemImage) }
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
                .environmentObject(store)
                .environmentObject(themeStore)
                .environmentObject(languageStore)
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
        .onReceive(NotificationCenter.default.publisher(for: .openAddWord)) { _ in
            selectedTab = .home
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showAddWordView = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .copiedToClipboard)) { _ in
            Haptics.tick()
            copiedToastToken += 1
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                copiedToast = true
            }
            Task { @MainActor in
                let token = copiedToastToken
                try? await Task.sleep(for: .seconds(1.8))
                guard token == copiedToastToken else { return }
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

            if copiedToast, selectedTab == .list {
                BannerToastView(
                    type: .dark,
                    message: String(localized: "Copied"),
                    icon: "doc.on.doc.fill",
                    duration: 1.5,
                    fromEdge: .top,
                    compact: true
                )
                .id(copiedToastToken)
                .padding(.top, 8)
                .zIndex(201)
            }
        }
        .overlay(alignment: .bottom) {
            if copiedToast, selectedTab != .list {
                BannerToastView(
                    type: .success,
                    message: String(localized: "Copied"),
                    duration: 1.5,
                    fromEdge: .bottom,
                    compact: true
                )
                .id(copiedToastToken)
                .padding(.bottom, 58)
                .zIndex(201)
            }
        }
    }

    private var mainContent: some View {
        ScrollViewReader { _ in
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                ProfileHeaderView(
                    onOpenStreak: {
                        Haptics.softTap()
                        showStreakCalendar = true
                    }
                )
                    .padding(.bottom, 16)

                DailyLessonCard(
                    plan: dailyLessonPlan,
                    onStart: {
                        showDailyLesson = true
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

                if showHomeReading,
                   network.isConnected,
                   store.words.filter({ $0.translation?.isEmpty == false }).count >= 3 {
                    ReadingStoryCard {
                        Haptics.buttonPress()
                        showStory = true
                    }
                    .padding(.horizontal, 20)
                }

                if showWordPacksSection {
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

                if showDailyChallengesSection, challengeManager.showsOnHome {
                    DailyChallengeButton(manager: challengeManager) {
                        showChallenges = true
                    }
                    .accessibilityLabel(Text("Daily Challenges"))
                    .accessibilityHint(Text("\(challengeManager.completedCount) of \(challengeManager.challenges.count) completed"))
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if dueWordsCount == 0,
                   !reviewTimerDismissed,
                   let info = nextReviewInfo {
                    HomeNextReviewCard(count: info.count, date: info.date) {
                        reviewTimerDismissed = true
                    }
                }

                if network.isConnected,
                   suggested.isLoading || !suggested.suggestedWords.isEmpty || suggested.lastError != nil {
                    SuggestedWordsView()
                        .environmentObject(suggested)
                        .padding(.horizontal, 20)
                }

                if !network.isConnected {
                    StatusBannerView(
                        icon: "wifi.slash",
                        iconColor: themeStore.accentGold,
                        title: "You're offline",
                        subtitle: "Dictionary works. AI features wait for a connection.",
                        useCard: true
                    )
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
                                reaction: word.reaction,
                                storedWord: word
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
                    let empty = DuoChaosCopy.homeEmpty(hasWords: hasEverAddedWord)
                    PracticeEmptyContent(
                        icon: "text.badge.plus",
                        title: hasEverAddedWord
                            ? String(localized: "No recent words")
                            : String(localized: "Your word garden is waiting"),
                        subtitle: empty.subtitle,
                        tip: String(localized: "One word unlocks lessons and practice"),
                        ctaTitle: LocalizedStringKey(empty.cta),
                        onCTA: {
                            Haptics.buttonPress()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showAddWordView = true
                            }
                        }
                    )
                    .padding(.top, 12)
                    .frame(minHeight: 320)
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

            presentPendingBadgeCelebrationIfNeeded()
        }
        .onChange(of: store.revision) { _, _ in refreshCachedWordData() }
        .onChange(of: badgeStore.quizCompletions) { _, _ in presentPendingBadgeCelebrationIfNeeded() }
        .onChange(of: badgeStore.suggestedWordsAccepted) { _, _ in presentPendingBadgeCelebrationIfNeeded() }
        .onChange(of: activeMilestone) { _, newValue in
            if newValue == nil {
                presentPendingBadgeCelebrationIfNeeded()
            }
        }
        }
    }

    private func presentPendingBadgeCelebrationIfNeeded() {
        guard activeMilestone == nil else { return }
        let streak = WordsStore.computeCurrentStreak(from: store.words)
        badgeStore.checkForNewUnlocks(totalWords: store.totalWordsAdded, currentStreak: streak)
        guard let badge = badgeStore.pendingCelebration else { return }
        badgeStore.dismissPendingCelebration()
        activeMilestone = .badge(
            id: badge.id,
            emoji: badge.emoji,
            title: String(localized: "Badge unlocked!"),
            message: "\(badge.title) — \(badge.description)"
        )
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
        .cleanCard(themeStore: themeStore, cornerRadius: DesignRadius.large)
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
        guard FeatureGates.homeChatEnabled, showHomeChat else { return }
        guard network.isConnected else { return }
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
        guard network.isConnected else { return }
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

#Preview {
    HomeView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
        .environmentObject(BadgeStore())
        .environmentObject(SuggestedWordsStore())
        .environmentObject(StudyTimeTracker.shared)
}
