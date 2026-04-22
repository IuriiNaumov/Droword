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
    @AppStorage(AppStorageKeys.hasSeenFirstWords) private var hasSeenFirstWords: Bool = false
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasEverAddedWord) private var hasEverAddedWord: Bool = false
    @AppStorage(AppStorageKeys.hasSeenStreakPaywall) private var hasSeenStreakPaywall: Bool = false
    @AppStorage(AppStorageKeys.hasSeenPerfectQuizPaywall) private var hasSeenPerfectQuizPaywall: Bool = false
    @AppStorage(AppStorageKeys.lastCelebratedStreak) private var lastCelebratedStreak: Int = 0
    @State private var showFirstWords = false
    @State private var showSuggestedIntro = false
    @State private var showMotivationalPaywall = false
    @State private var pendingStreakPaywall = false
    @State private var showChallenges = false
    @State private var showPremiumFromLimit = false
    @State private var showCoachMarks = false
    @State private var enrichmentToast: String?
    @State private var copiedToast = false
    @State private var cachedRecentWords: [StoredWord] = []
    @State private var cachedDueWordsCount: Int = 0
    @State private var cachedNextReviewInfo: (count: Int, date: Date)? = nil
    @State private var recentCardAppeared: Set<UUID> = []
    @State private var lastSuggestionTodayCount: Int?
    @State private var reviewTimerDismissed = false
    @State private var scrollProxy: ScrollViewProxy?
    @Environment(\.colorScheme) private var colorScheme

    private var iconCircleFill: Color {
        themeStore.iconCircleFill(colorScheme: colorScheme)
    }

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
            title: "React to Words",
            message: "Double tap any card to add an emoji reaction. Tap the reaction to change it. A fun way to mark your favourites!",
            icon: "hand.tap.fill"
        ),
        CoachMarkStep(
            title: "Smart Repetition",
            message: "The app uses spaced repetition — you review words right before you'd forget them. Easy words come back less often, hard words more.",
            icon: "clock.arrow.2.circlepath"
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

    @AppStorage(AppStorageKeys.reviewAllCaughtUp) private var reviewAllCaughtUp: Bool = false

    private var dueWordsCount: Int { cachedDueWordsCount }

    private var nextReviewInfo: (count: Int, date: Date)? { cachedNextReviewInfo }

    private func timeUntil(_ date: Date) -> String {
        let seconds = max(0, date.timeIntervalSince(Date()))
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return String(localized: "\(max(1, minutes)) min")
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(localized: "\(hours) h")
        }
        let days = hours / 24
        return String(localized: "\(days) d")
    }

    private func longIntervalHint(for date: Date) -> LocalizedStringKey? {
        let days = max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
        guard days >= 3 else { return nil }

        let hints: [LocalizedStringKey]
        if days >= 30 {
            hints = [
                "You've mastered these words so well, they need a long break 💪",
                "Your brain locked these in tight. See you in a month!",
                "These words are basically muscle memory now 🧠",
                "Practice paid off — these words are deeply stored"
            ]
        } else if days >= 14 {
            hints = [
                "Great progress — these words are sticking 🎯",
                "Your practice sessions are really paying off",
                "These words are getting into long-term memory 🧩",
                "Almost mastered — just a couple more reviews to go"
            ]
        } else {
            hints = [
                "Words are settling in nicely, keep it up ✨",
                "Spaced repetition is working its magic",
                "You're building strong memory foundations 🌱",
                "Right on track — see you in a few days"
            ]
        }

        let index = abs(date.hashValue) % hints.count
        return hints[index]
    }

    private func refreshCachedWordData() {
        cachedRecentWords = Array(store.words.sorted(by: { $0.dateAdded > $1.dateAdded }).prefix(3))

        let now = Date()
        cachedDueWordsCount = store.words.filter { w in
            guard let due = w.dueDate else { return false }
            return due <= now
        }.count

        let upcoming = store.words.compactMap { w -> Date? in
            guard let due = w.dueDate, due > now else { return nil }
            return due
        }.sorted()
        if let earliest = upcoming.first {
            let count = upcoming.filter { Calendar.current.isDate($0, equalTo: earliest, toGranularity: .hour) }.count
            cachedNextReviewInfo = (count, earliest)
        } else {
            cachedNextReviewInfo = nil
        }
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
            .fullScreenCover(isPresented: $showMotivationalPaywall) {
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
                    MilestoneCelebrationView(
                        milestone: milestone,
                        wordsCount: store.words.count,
                        daysSinceStart: {
                            let str = UserDefaults.standard.string(forKey: AppStorageKeys.firstUseDate) ?? ""
                            guard let start = DateFormatting.dayFormatter.date(from: str) else { return 1 }
                            return max(1, Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 1)
                        }()
                    ) {
                        let wasStreak = {
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
            .onReceive(NotificationCenter.default.publisher(for: .perfectQuizCompleted)) { _ in
                guard !isPremium && !hasSeenPerfectQuizPaywall else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    hasSeenPerfectQuizPaywall = true
                    showMotivationalPaywall = true
                }
            }
            .onChange(of: pendingStreakPaywall) { _, pending in
                guard pending else { return }
                pendingStreakPaywall = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    hasSeenStreakPaywall = true
                    showMotivationalPaywall = true
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
        HStack(spacing: 12) {
            StatusBannerView(
                icon: "clock.fill",
                iconColor: themeStore.accentGold,
                title: "Daily limit reached",
                subtitle: "New words won't get translations until tomorrow. Upgrade to Pro for unlimited."
            )
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeStore.accentBlue)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
        .onTapGesture {
            Haptics.lightImpact()
            showPremiumFromLimit = true
        }
        .accessibilityLabel(Text("Daily limit reached"))
        .accessibilityHint(Text("Tap to upgrade to Pro"))
    }

    private var mainContent: some View {
        ScrollViewReader { proxy in
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ProfileHeaderView()
                    .padding(.bottom, 60)
                StatsView()

                WordPacksSectionView()

                Button {
                    Haptics.lightImpact()
                    showChallenges = true
                } label: {
                    DailyChallengeButton(manager: challengeManager)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Daily Challenges"))
                .accessibilityHint(Text("\(challengeManager.completedCount) of \(challengeManager.challenges.count) completed"))
                .padding(.horizontal, 20)

                if dueWordsCount > 0 && !reviewAllCaughtUp && store.words.count >= 5 {
                    Button {
                        Haptics.lightImpact()
                        withAnimation {
                            scrollProxy?.scrollTo("reviewSection", anchor: .top)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(iconCircleFill)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "clock.badge.exclamationmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(themeStore.accentGold)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Review")
                                    .font(themeStore.bold(16))
                                    .foregroundColor(themeStore.mainText)
                                Text("\(dueWordsCount) words to review")
                                    .font(themeStore.regular(13))
                                    .foregroundColor(themeStore.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeStore.accentBlue)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                        )
                        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }

                if dueWordsCount == 0 && !reviewTimerDismissed, let info = nextReviewInfo {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(iconCircleFill)
                                .frame(width: 44, height: 44)
                            Image(systemName: "timer")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeStore.accentBlue)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next Review")
                                .font(themeStore.bold(16))
                                .foregroundColor(themeStore.mainText)
                            Text("\(info.count) words to review in \(timeUntil(info.date))")
                                .font(themeStore.regular(13))
                                .foregroundColor(themeStore.secondaryText)
                            if let hint = longIntervalHint(for: info.date) {
                                Text(hint)
                                    .font(themeStore.regular(12))
                                    .foregroundColor(themeStore.accentGold)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer()
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) {
                                reviewTimerDismissed = true
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeStore.accentBlue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                    )
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                ReviewSectionView()
                    .id("reviewSection")
                    .padding(.horizontal, 20)

                SuggestedWordsView()
                    .environmentObject(suggested)
                    .padding(.horizontal, 20)

                if !cachedRecentWords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently added")
                            .font(themeStore.bold(24))
                            .foregroundColor(themeStore.mainText)
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
                            Haptics.lightImpact()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showAddWordView = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text(hasEverAddedWord ? "Add a word" : "Add your first word")
                            }
                            .duo3DStyle(themeStore.mainAccentColor)
                        }
                        .buttonStyle(Duo3DButtonStyle())
                        .padding(.horizontal, 20)

                        Text(hasEverAddedWord ? "Your recent words will appear here." : "That's all it takes to start learning.")
                            .font(themeStore.regular(14))
                            .foregroundColor(themeStore.secondaryText)
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
            refreshCachedWordData()
            challengeManager.refreshIfNeeded()

            if !hasSeenFirstWords && store.words.isEmpty,
               StarterWordBank.words(learning: languageStore.learningLanguage, native: languageStore.nativeLanguage) != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showFirstWords = true
                    }
                }
            } else if !hasSeenCoachMarks && hasSeenFirstWords {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCoachMarks = true
                    }
                }
            }

            // Streak milestone detection
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
        .onChange(of: store.words.count) { refreshCachedWordData() }
        .onChange(of: store.revision) { refreshCachedWordData() }
        .onAppear { scrollProxy = proxy }
        }
    }

}

#Preview {
    HomeView()
        .environmentObject(WordsStore())
}
