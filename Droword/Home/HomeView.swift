import SwiftUI
import AVFoundation

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @StateObject private var golden = GoldenWordsStore()

    @State private var showAddWordView = false
    @State private var sharedWord: String = ""
    @State private var selectedTab: Tab = .home
    @State private var lastGoldenTrigger = 0
    @State private var activeMilestone: MilestoneType?
    @AppStorage("lastCelebratedWordCount") private var lastCelebratedWordCount: Int = 0
    @AppStorage("lastCelebratedDailyGoal") private var lastCelebratedDailyGoalDate: String = ""
    @AppStorage("hasSeenGoldenIntro") private var hasSeenGoldenIntro: Bool = false
    @AppStorage("seasonalEffectsEnabled") private var seasonalEffectsEnabled: Bool = true
    @AppStorage("seasonalAnimationEnabled") private var seasonalAnimationEnabled: Bool = true
    @AppStorage("dailyGoalDismissedDate") private var dailyGoalDismissedDate: String = ""
    @State private var showGoldenIntro = false

    enum Tab: String, CaseIterable, Identifiable {
        case home
        case practice
        case add
        case list

        var id: String { rawValue }
    }

    private var isCompact: Bool { hSize == .compact }
    private var horizontalPadding: CGFloat { isCompact ? 16 : 20 }

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

    @AppStorage("dailyGoalTarget") private var dailyGoalTarget: Int = 5
    @AppStorage("dailyGoalDate") private var dailyGoalDate: String = ""

    private var wordsAddedToday: Int {
        store.words.filter { Calendar.current.isDateInToday($0.dateAdded) }.count
    }

    private var isGoalCompleted: Bool {
        wordsAddedToday >= max(1, dailyGoalTarget)
    }

    private var isDailyGoalDismissedToday: Bool {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return dailyGoalDismissedDate == df.string(from: Date())
    }

    private func refreshDailyGoalIfNeeded() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        guard dailyGoalDate != today else { return }
        dailyGoalDate = today
        dailyGoalTarget = Int.random(in: 3...10)
    }

    private var dueWordCount: Int {
        let now = Date()
        return store.words.filter { w in
            guard let due = w.dueDate else { return true }
            return due <= now
        }.count
    }
    
    private var dueWordUnit: String {
        dueWordCount == 1 ? "word" : "words"
    }

    private var recentWords: [StoredWord] {
        Array(store.words.sorted(by: { $0.dateAdded > $1.dateAdded }).prefix(3))
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
            .tint(Color.mainBlack)
            .background(Color.appBackground.ignoresSafeArea())
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
        .onChange(of: store.words.count) { oldValue, newValue in
            // Only react to additions, not deletions
            guard newValue > oldValue else { return }

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
                let todayCount = store.words.filter { Calendar.current.isDateInToday($0.dateAdded) }.count
                let effectiveTarget = max(1, dailyGoalTarget)
                if todayCount >= effectiveTarget {
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

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ProfileHeaderView()
                StatsView()

                if !isDailyGoalDismissedToday {
                    dailyGoalWidget
                        .padding(.horizontal, 20)
                }

                if dueWordCount > 0 {
                    Button {
                        Haptics.mediumImpact()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = .practice
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Practice \(dueWordCount) \(dueWordUnit)")
                                .font(.custom("Poppins-Bold", size: 17))
                        }
                        .foregroundColor(.white)
                    }
                    .duo3DStyle(themeStore.buttonAccent)
                    .buttonStyle(Duo3DButtonStyle())
                    .padding(.horizontal, 20)
                }

                GoldenWordsView()
                    .environmentObject(golden)
                    .padding(.horizontal, 20)

                if !recentWords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently added")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.mainBlack)
                            .padding(.horizontal, 20)

                        ForEach(recentWords) { word in
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
                        title: "Add your first word",
                        subtitle: "That's all it takes to start learning."
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.bottom, 60)
        }
        .background {
            ZStack {
                Color.appBackground
                if seasonalEffectsEnabled {
                    SeasonalOverlayView(animated: seasonalAnimationEnabled)
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear { refreshDailyGoalIfNeeded() }
    }

    private var dailyGoalWidget: some View {
        let progress = min(1.0, Double(wordsAddedToday) / Double(max(1, dailyGoalTarget)))
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(themeStore.accentGreen.opacity(0.2), lineWidth: 6)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(themeStore.accentGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                if isGoalCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(themeStore.accentGreen)
                } else {
                    Text("🔥")
                        .font(.system(size: 22))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if isGoalCompleted {
                    Text("Goal reached!")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.mainBlack)
                    Text("Great job, you did it today!")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)
                } else {
                    Text("Daily goal")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.mainBlack)
                    Text("\(wordsAddedToday)/\(dailyGoalTarget) words today")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)
                }
            }
            Spacer()

            if isGoalCompleted {
                Button {
                    Haptics.lightImpact()
                    let df = DateFormatter()
                    df.calendar = Calendar(identifier: .gregorian)
                    df.dateFormat = "yyyy-MM-dd"
                    withAnimation(.easeOut(duration: 0.25)) {
                        dailyGoalDismissedDate = df.string(from: Date())
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.mainGrey)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.mainGrey.opacity(0.1))
                        ).padding(.bottom, 22)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.divider, lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(WordsStore())
}
