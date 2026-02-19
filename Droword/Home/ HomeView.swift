import SwiftUI
import AVFoundation

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var store: WordsStore
    @StateObject private var golden = GoldenWordsStore()

    @State private var showAddWordView = false
    @State private var selectedTab: Tab = .home
    @State private var lastGoldenTrigger = 0

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

    private var recentWords: [StoredWord] {
        Array(store.words.sorted(by: { $0.dateAdded > $1.dateAdded }).prefix(3))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                mainContent
                    .tabItem { icon(for: .home) }
                    .tag(Tab.home)

                DictionaryView()
                    .tabItem { icon(for: .list) }
                    .tag(Tab.list)
                
                PracticeView()
                    .tabItem { icon(for: .practice) }
                    .tag(Tab.practice)

                Color.clear
                    .tabItem { icon(for: .add) }
                    .tag(Tab.add)
            }
            .tint(.mainBlack)
            .background(Color.appBackground.ignoresSafeArea())
            .onChange(of: selectedTab) { _, newValue in
                if newValue == .add {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showAddWordView = true
                    }
                    selectedTab = .home
                }
            }
            .sheet(isPresented: $showAddWordView) {
                AddWordView(store: store)
                    .transaction { $0.disablesAnimations = true }
            }
            .environmentObject(golden)
        }
        .onChange(of: store.words.count) { _, newValue in
            if newValue > 0, newValue % 5 == 0, newValue != lastGoldenTrigger {
                Task {
                    await golden.fetchSuggestions(basedOn: store.words, languageStore: LanguageStore())
                }
                lastGoldenTrigger = newValue
            }
        }
    }

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                ProfileHeaderView()
                StatsView()
                GoldenWordsView()
                    .environmentObject(golden)
                    .padding(.horizontal, horizontalPadding)

                if !recentWords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently added")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(Color(.mainBlack))
                            .padding(.horizontal, horizontalPadding)

                        ForEach(recentWords) { word in
                            WordCardView(
                                word: word.word,
                                translation: word.translation,
                                type: word.type,
                                example: word.example,
                                transcription: word.transcription,
                                comment: word.breakdown,
                                explanation: word.explanation,
                                breakdown: word.comment,
                                tag: word.tag
                            ) {
                                store.remove(word)
                            }
                            .padding(.horizontal, horizontalPadding)
                        }
                    }
                    .padding(.top, 8)
                } else {
                    EmptyListView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(.bottom, 60)
        }
        .background(Color(.appBackground))
    }

    @ViewBuilder
    private func icon(for tab: Tab) -> some View {
        switch tab {
        case .home:
            Image(systemName: "house.fill")
        case .practice:
            Image(systemName: "rectangle.portrait.on.rectangle.portrait")
        case .list:
            Image(systemName: "book.fill")
        case .add:
            Image(systemName: "plus.circle.fill")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(WordsStore())
}
