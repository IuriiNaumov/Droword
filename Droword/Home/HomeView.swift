import SwiftUI
import AVFoundation

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @StateObject private var golden = GoldenWordsStore()

    @State private var showAddWordView = false
    @State private var selectedTab: Tab = .home
    @State private var lastGoldenTrigger = 0
    @State private var activeMilestone: MilestoneType?
    @AppStorage("lastCelebratedWordCount") private var lastCelebratedWordCount: Int = 0
    @AppStorage("lastCelebratedDailyGoal") private var lastCelebratedDailyGoalDate: String = ""

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

    private var wordsAddedToday: Int {
        store.words.filter { Calendar.current.isDateInToday($0.dateAdded) }.count
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
                AddWordView(store: store)
                    .environmentObject(themeStore)
                    .transaction { $0.disablesAnimations = true }
            }
            .environmentObject(golden)
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
            }
        }
        .onChange(of: store.words.count) { _, newValue in
            if newValue > 0, newValue % 5 == 0, newValue != lastGoldenTrigger {
                Task {
                    await golden.fetchSuggestions(basedOn: store.words, languageStore: LanguageStore())
                }
                lastGoldenTrigger = newValue
            }

            let todayCount = store.words.filter { Calendar.current.isDateInToday($0.dateAdded) }.count
            let target = UserDefaults.standard.integer(forKey: "dailyGoalTarget")
            let effectiveTarget = target > 0 ? target : 5
            if todayCount == effectiveTarget {
                NotificationManager.shared.scheduleDailyGoalCompletion()
                let todayStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
                if lastCelebratedDailyGoalDate != todayStr {
                    lastCelebratedDailyGoalDate = todayStr
                    activeMilestone = .dailyGoal
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

                StreakCalendarView()
                    .padding(.horizontal, 20)

                dailyGoalWidget
                    .padding(.horizontal, 20)

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
                    .duo3DStyle(Color.accentBlack)
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
                    EmptyListView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(.bottom, 60)
        }
        .background(Color.appBackground)
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
                Text("🔥")
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily goal")
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundColor(.mainBlack)
                Text("\(wordsAddedToday)/\(dailyGoalTarget) words today")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.mainGrey)
            }
            Spacer()
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
