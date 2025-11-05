import SwiftUI
import AVFoundation

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var store: WordsStore

    @State private var selectedTag: String? = nil
    @State private var selectedTab: Tab = .home
    @State private var showAddWordView = false
    @State private var isLoading = true
    @State private var isHoveringHome = false

    @State private var cachedTag: String? = nil
    @State private var cachedWords: [StoredWord] = []
    @State private var cachedFiltered: [StoredWord] = []

    enum Tab: String, CaseIterable, Identifiable {
        case home, trophy, add
        var id: String { rawValue }
        var title: String {
            switch self {
            case .home: return "Home"
            case .trophy: return "Stats"
            case .add: return "Add"
            }
        }
        var icon: String {
            switch self {
            case .home: return "house"
            case .trophy: return "trophy"
            case .add: return "plus.circle.fill"
            }
        }
    }

    private var filteredWords: [StoredWord] {
        cachedFiltered
    }

    private var isCompact: Bool { hSize == .compact }
    private var horizontalPadding: CGFloat { isCompact ? 16 : 20 }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                mainContent
                    .tabItem {
                        icon(for: .home)
                    }
                    .tag(Tab.home)

                Text("Your achievements")
                    .font(.custom("Poppins-Regular", size: 20))
                    .tabItem {
                        icon(for: .trophy)
                    }
                    .tag(Tab.trophy)

                Color.clear
                    .tabItem {
                        Image(systemName: Tab.add.icon)
                    }
                    .tag(Tab.add)
            }
            .tint(.black)
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == .add {
                    selectedTab = oldValue ?? .home
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showAddWordView = true
                    }
                }
            }
        }
        .sheet(isPresented: $showAddWordView) {
            AddWordView(store: store)
                .transaction { $0.disablesAnimations = true }
        }
        .onAppear {
            recalculateFiltered()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
        .onChange(of: selectedTag) { _ in recalculateFiltered() }
        .onChange(of: store.words) { _ in recalculateFiltered() }
    }

    private func recalculateFiltered() {
        let tag = selectedTag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if tag == cachedTag, store.words == cachedWords {
            return
        }
        if tag.isEmpty {
            cachedFiltered = store.words
        } else {
            cachedFiltered = store.words.filter {
                ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == tag.lowercased()
            }
        }
        cachedTag = tag
        cachedWords = store.words
    }

    @ViewBuilder
    private func icon(for tab: Tab) -> some View {
        switch tab {
        case .home:
            Image(systemName: "house.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    (selectedTab == .home || isHoveringHome)
                    ? AnyShapeStyle(Color.red)
                    : AnyShapeStyle(.secondary),
                    (selectedTab == .home || isHoveringHome)
                    ? AnyShapeStyle(Color(red: 0.95, green: 0.90, blue: 0.82))
                    : AnyShapeStyle(.secondary)
                )
                .scaleEffect(selectedTab == .home ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                .onHover { hovering in
                    isHoveringHome = hovering
                }
        case .trophy:
            Image(systemName: "trophy.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    selectedTab == .trophy ? Color.yellow : .secondary
                )
                .scaleEffect(selectedTab == .trophy ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
        case .add:
            Image(systemName: "plus.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    selectedTab == .add ? Color.black : .secondary
                )
                .scaleEffect(selectedTab == .add ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Hi, Yura")
                    .font(.custom("Poppins-Bold", size: 34))
                Spacer()
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 10)

            TagsView(selectedTag: $selectedTag)
                .padding(.horizontal, horizontalPadding)

            Text(selectedTag == nil
                 ? "You have \(filteredWords.count) words"
                 : "You have \(filteredWords.count) words in \(selectedTag!)")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal, horizontalPadding)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    if isLoading {
                        Skeleton()
                    } else if filteredWords.isEmpty {
                        Skeleton()
                    } else {
                        ForEach(filteredWords) { word in
                            WordCardView(
                                word: word.word,
                                translation: word.translation,
                                type: word.type,
                                example: word.example,
                                comment: word.comment,
                                tag: word.tag
                            ) {
                                store.remove(word)
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    HomeView().environmentObject(WordsStore())
}
