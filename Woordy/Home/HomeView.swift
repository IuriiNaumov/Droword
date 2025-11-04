import SwiftUI
import AVFoundation

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTag: String? = nil
    @State private var selectedTab: Tab = .home
    @State private var activeTabPulse: Tab? = nil
    @State private var showAddWordView = false

    @EnvironmentObject private var store: WordsStore

    enum Tab: String, CaseIterable, Identifiable {
        case home, trophy, search
        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .home: return "house"
            case .trophy: return "trophy"
            case .search: return "magnifyingglass"
            }
        }
    }


    private var filteredWords: [StoredWord] {
        guard let tag = selectedTag?.trimmingCharacters(in: .whitespacesAndNewlines), !tag.isEmpty else {
            return store.words
        }
        let normalizedTag = tag.lowercased()
        return store.words.filter { ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTag }
    }

    private var isCompact: Bool { hSize == .compact }
    private var headerTopPadding: CGFloat { isCompact ? 8 : 12 }
    private var sectionSpacing: CGFloat { isCompact ? 18 : 24 }
    private var horizontalPadding: CGFloat { isCompact ? 16 : 20 }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {

            HStack {
                Text("Hi, Yura")
                    .font(.custom("Poppins-Bold", size: 34))
                Spacer()
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                        .contentShape(Rectangle())
                        .padding(8)
                }
                .buttonStyle(.plain)
                .padding(.trailing, horizontalPadding)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, 10)

            TagsView(selectedTag: $selectedTag)
                .padding(.horizontal, horizontalPadding)

            Text(selectedTag == nil
                 ? "You have \(filteredWords.count) words"
                 : "You have \(filteredWords.count) words in \(selectedTag!)")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 4)

            ScrollView(showsIndicators: false) {
                if filteredWords.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(selectedTag == nil ? "No words yet" : "No words for this tag")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .padding(.horizontal, horizontalPadding)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredWords) { word in
                            WordCardView(
                                word: word.word,
                                translation: word.translation,
                                type: word.type,
                                example: word.example,
                                comment: word.comment,
                                tag: word.tag,
                                onDelete: {
                                    if let index = store.words.firstIndex(where: { $0.id == word.id }) {
                                        let toRemove = store.words[index]
                                        store.remove(toRemove)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            }


        }
        .onAppear {
            print("[HomeView] words count:", store.words.count)
            for w in store.words { print("[HomeView] word:", w.word, "tag:", w.tag ?? "nil") }
        }
        .safeAreaInset(edge: .bottom) {
            LiquidGlassTabBar(
                selectedTab: $selectedTab,
                showAddWordView: $showAddWordView,
                activeTabPulse: $activeTabPulse,
                isCompact: isCompact
            )
        }
        .fullScreenCover(isPresented: $showAddWordView) {
            AddWordView().environmentObject(store)
        }
    }


    private func iconName(for tab: Tab) -> String {
        switch tab {
        case .search:
            return tab.systemImage 
        default:
            return selectedTab == tab ? tab.systemImage + ".fill" : tab.systemImage
        }
    }
}

struct WordCard: Identifiable {
    let id = UUID()
    let word: String
    let translation: String?
    let comment: String?
    let category: String
}

#Preview {
    let store = WordsStore()
    if store.words.isEmpty {
        store.add(StoredWord(word: "apple", type: "noun", translation: "яблоко",example: "яблоко", comment: "fruit", tag: "food"))
        store.add(StoredWord(word: "run", type: "verb", translation: "бежать", example: "яблоко", comment: nil, tag: "verbs"))
    }
    return HomeView()
        .environmentObject(store)
}
