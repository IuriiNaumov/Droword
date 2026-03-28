import SwiftUI
import AVFoundation

struct HomeView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @StateObject private var golden = GoldenWordsStore()
    @StateObject private var challengeManager = DailyChallengeManager.shared

    @State private var showAddWordView = false
    @State private var sharedWord: String = ""
    @State private var selectedTab: Tab = .home
    @State private var lastGoldenTrigger = 0
    @State private var activeMilestone: MilestoneType?
    @AppStorage("lastCelebratedWordCount") private var lastCelebratedWordCount: Int = 0
    @AppStorage("lastCelebratedDailyGoal") private var lastCelebratedDailyGoalDate: String = ""
    @AppStorage("hasSeenGoldenIntro") private var hasSeenGoldenIntro: Bool = false
    @AppStorage("seasonalEffectsEnabled") private var seasonalEffectsEnabled: Bool = false
    @AppStorage("seasonalAnimationEnabled") private var seasonalAnimationEnabled: Bool = true
    @AppStorage("hasSeenCoachMarks") private var hasSeenCoachMarks: Bool = false
    @AppStorage("isPremium") private var isPremium: Bool = false
    @State private var showGoldenIntro = false
    @State private var showChallenges = false
    @State private var showPremiumFromLimit = false
    @State private var showCoachMarks = false
    @State private var enrichmentToast: String?
    @State private var cachedRecentWords: [StoredWord] = []
    @State private var previousWordCount: Int?

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
        case 0..<50: return ("Beginner 🐣", 0, 50)
        case 50..<150: return ("Explorer 🦊", 50, 150)
        case 150..<300: return ("Linguist 🦉", 150, 300)
        case 300..<600: return ("Master 🐉", 300, 600)
        default: return ("Legend 🌟", 600, 1000)
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                mainContent
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(Tab.home)

                DictionaryView()
                    .tabItem { Label("Dictionary", systemImage: "book.fill") }
                    .tag(Tab.list)

                PracticeView()
                    .tabItem { Label("Practice", systemImage: "rectangle.portrait.on.rectangle.portrait") }
                    .tag(Tab.practice)

                Color.clear
                    .tabItem { Label("Add", systemImage: "plus.circle.fill") }
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
            } content: {
                AddWordView(initialWord: sharedWord, store: store)
                    .environmentObject(themeStore)
                    .transaction { $0.disablesAnimations = true }
            }
            .environmentObject(golden)
            .fullScreenCover(isPresented: $showChallenges) {
                DailyChallengeDetailView(manager: challengeManager)
                    .environmentObject(themeStore)
            }
            .fullScreenCover(isPresented: $showPremiumFromLimit) {
                PremiumView(asWall: true)
                    .environmentObject(themeStore)
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

                if showGoldenIntro {
                    GoldenWordsIntroView {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showGoldenIntro = false
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
            }
            .onReceive(NotificationCenter.default.publisher(for: .wordsEnriched)) { notification in
                if let words = notification.userInfo?["words"] as? [String], !words.isEmpty {
                    let message: String
                    if words.count == 1 {
                        message = "\"\(words[0])\" updated with translation"
                    } else {
                        message = "\(words.count) words updated with translations"
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
        .onChange(of: golden.goldenWords.count) { _, newCount in
            if newCount > 0 && !hasSeenGoldenIntro {
                hasSeenGoldenIntro = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showGoldenIntro = true
                    }
                }
            }
        }
        .onChange(of: store.words.count) { _, newValue in
            let oldCount = previousWordCount ?? 0
            guard newValue > oldCount else {
                previousWordCount = newValue
                return
            }
            
            let addedCount = newValue - oldCount
            challengeManager.recordWordsAdded(count: addedCount)

            previousWordCount = newValue

            if newValue > 0, newValue % 5 == 0, newValue != lastGoldenTrigger {
                let isPremium = UserDefaults.standard.bool(forKey: "isPremium")
                if isPremium || DailyLimitsManager.canFetchGolden {
                    if !isPremium { DailyLimitsManager.recordGoldenFetch() }
                    Task {
                        await golden.fetchSuggestions(basedOn: store.words, languageStore: languageStore)
                    }
                }
                lastGoldenTrigger = newValue
            }

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

                GoldenWordsView()
                    .environmentObject(golden)
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

                        ForEach(cachedRecentWords) { word in
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
                        }
                    }
                    .padding(.top, 4)
                } else {
                    EmptyListView(
                        icon: "heart.fill",
                        title: store.words.isEmpty ? "Add your first word" : "Add a word",
                        subtitle: store.words.isEmpty ? "That's all it takes to start learning." : "Your recent words will appear here."
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
