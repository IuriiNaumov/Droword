import SwiftUI
import AVFoundation

struct HomeView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @EnvironmentObject private var suggested: SuggestedWordsStore
    @StateObject private var challengeManager = DailyChallengeManager.shared

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
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasEverAddedWord) private var hasEverAddedWord: Bool = false
    @State private var showSuggestedIntro = false
    @State private var showChallenges = false
    @State private var showPremiumFromLimit = false
    @State private var showCoachMarks = false
    @State private var enrichmentToast: String?
    @State private var copiedToast = false
    @State private var cachedRecentWords: [StoredWord] = []
    @State private var recentCardAppeared: Set<UUID> = []
    @State private var lastSuggestionTodayCount: Int?

    enum Tab: String, CaseIterable, Identifiable {
        case home
        case practice
        case add
        case list

        var id: String { rawValue }
    }

    private var level: (name: String, min: Int, max: Int) {
        let total = store.words.count
        switch total {
        case 0..<50: return (String(localized: "Beginner 🐣"), 0, 50)
        case 50..<150: return (String(localized: "Explorer 🦊"), 50, 150)
        case 150..<300: return (String(localized: "Linguist 🦉"), 150, 300)
        case 300..<600: return (String(localized: "Master 🐉"), 300, 600)
        default: return (String(localized: "Legend 🌟"), 600, 1000)
        }
    }

    private var progressToNextLevel: Double {
        let total = Double(store.words.count)
        let minVal = Double(level.min)
        let maxVal = Double(level.max)
        return min(1.0, (total - minVal) / (maxVal - minVal))
    }

    private let coachMarkSteps: [CoachMarkStep] = [
        CoachMarkStep(
            title: "Add Words",
            message: "Tap the + tab to add new words. I'll translate them, find examples, and create flashcards automatically.",
            icon: "plus.circle.fill"
        ),
        CoachMarkStep(
            title: "Review Cards",
            message: "Words appear on the home screen when it's time to review. Swipe through them to keep your memory fresh.",
            icon: "rectangle.portrait.on.rectangle.portrait"
        ),
        CoachMarkStep(
            title: "Practice Quizzes",
            message: "Go to Practice for multiple choice, typing, and fill-in-the-blank quizzes. Choose your preferred direction — word to translation or vice versa.",
            icon: "brain.head.profile"
        ),
        CoachMarkStep(
            title: "Listening Mode",
            message: "Put on headphones and learn while doing other things. Audio flashcards with customizable pauses and speed.",
            icon: "headphones"
        ),
        CoachMarkStep(
            title: "Track Your Progress",
            message: "Tap your stats to see detailed charts, streaks, and achievements. Every word counts toward your goals.",
            icon: "chart.bar.fill"
        ),
    ]

    private func refreshCachedWordData() {
        cachedRecentWords = Array(store.words.sorted(by: { $0.dateAdded > $1.dateAdded }).prefix(3))
    }

    private var todayWordsCount: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return store.words.filter { $0.dateAdded >= startOfDay }.count
    }

    private func checkSuggestionTrigger() {
        let todayCount = todayWordsCount
        guard todayCount > 0, todayCount % 5 == 0, todayCount != lastSuggestionTodayCount else { return }
        lastSuggestionTodayCount = todayCount

        let isPremium = UserDefaults.standard.bool(forKey: AppStorageKeys.isPremium)
        if isPremium || DailyLimitsManager.canFetchSuggestions {
            if !isPremium { DailyLimitsManager.recordSuggestionFetch() }
            Task {
                await suggested.fetchSuggestions(basedOn: store.words, languageStore: languageStore)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                mainContent
                    .tabItem { Label("", systemImage: "house.fill") }
                    .tag(Tab.home)

                DictionaryView()
                    .tabItem { Label("", systemImage: "rectangle.portrait.on.rectangle.portrait") }
                    .tag(Tab.list)

                PracticeView()
                    .tabItem { Label("", systemImage: "lightbulb.fill") }
                    .tag(Tab.practice)

                Color.clear
                    .tabItem { Label("", systemImage: "plus.circle.fill") }
                    .tag(Tab.add)
            }
            .tint(themeStore.tabTint)
            .background(themeStore.appBg.ignoresSafeArea())
            .onChange(of: selectedTab) { _, newValue in
                Haptics.selection()
                if newValue == .add {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showAddWordView = true
                    }
                    selectedTab = .home
                }
            }
            .fullScreenCover(isPresented: $showAddWordView) {
                sharedWord = ""
                checkSuggestionTrigger()
            } content: {
                AddWordView(initialWord: sharedWord, store: store)
                    .environmentObject(themeStore)
                    .tint(themeStore.mainAccentColor)
                    .transaction { $0.disablesAnimations = true }
            }
            .environmentObject(suggested)
            .fullScreenCover(isPresented: $showChallenges) {
                DailyChallengeDetailView(manager: challengeManager)
                    .environmentObject(themeStore)
                    .tint(themeStore.mainAccentColor)
            }
            .fullScreenCover(isPresented: $showPremiumFromLimit) {
                PremiumView(asWall: true)
                    .environmentObject(themeStore)
                    .tint(themeStore.mainAccentColor)
            }
            .onReceive(NotificationCenter.default.publisher(for: .sharedWordReceived)) { notification in
                if let word = notification.userInfo?["word"] as? String {
                    sharedWord = word
                    showAddWordView = true
                }
            }
            .overlay {
                if let milestone = activeMilestone {
                    MilestoneCelebrationView(milestone: milestone) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            activeMilestone = nil
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
            }
            .overlay(alignment: .top) {
                if let toast = enrichmentToast {
                    BannerToastView(type: .success, message: toast)
                        .zIndex(200)
                }
                if copiedToast {
                    BannerToastView(type: .success, message: "Copied", duration: 1.5)
                        .zIndex(201)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .copiedToClipboard)) { _ in
                Haptics.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    copiedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        copiedToast = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .wordsEnriched)) { notification in
                if let words = notification.userInfo?["words"] as? [String], !words.isEmpty {
                    let message: String
                    if words.count == 1 {
                        message = String(localized: "\"\(words[0])\" updated with translation")
                    } else {
                        message = String(localized: "\(words.count) words updated with translations")
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        enrichmentToast = message
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            enrichmentToast = nil
                        }
                    }
                }
            }
        }
        .onChange(of: suggested.suggestedWords.count) { _, newCount in
            if newCount > 0 && !hasSeenSuggestedIntro {
                hasSeenSuggestedIntro = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSuggestedIntro = true
                    }
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

    private var enrichmentLimitBanner: some View {
        StatusBannerView(
            icon: "clock.fill",
            iconColor: themeStore.accentGold,
            title: "Daily limit reached",
            subtitle: "New words won't get translations until tomorrow. Upgrade to Pro for unlimited."
        )
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.accentGold.opacity(0.12))
        )
        .onTapGesture {
            Haptics.lightImpact()
            showPremiumFromLimit = true
        }
    }

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ProfileHeaderView()
                    .padding(.bottom, 60)
                StatsView()

                Button {
                    Haptics.lightImpact()
                    showChallenges = true
                } label: {
                    DailyChallengeButton(manager: challengeManager)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                ReviewSectionView()
                    .padding(.horizontal, 20)

                SuggestedWordsView()
                    .environmentObject(suggested)
                    .padding(.horizontal, 20)

                if !cachedRecentWords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently added")
                            .font(themeStore.bold(24))
                            .foregroundColor(themeStore.mainText)
                            .padding(.horizontal, 20)

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
                                tag: word.tag
                            ) {
                                store.remove(word)
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
                    EmptyListView(
                        icon: "heart.fill",
                        title: hasEverAddedWord ? "Add a word" : "Add your first word",
                        subtitle: hasEverAddedWord ? "Your recent words will appear here." : "That's all it takes to start learning."
                    )
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
            refreshCachedWordData()
            challengeManager.refreshIfNeeded()

            if !hasSeenCoachMarks {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCoachMarks = true
                    }
                }
            }
        }
        .onChange(of: store.words.count) { refreshCachedWordData() }
    }

}

#Preview {
    HomeView()
        .environmentObject(WordsStore())
}
