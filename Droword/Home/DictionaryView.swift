import SwiftUI

enum DictionarySortOption: String, CaseIterable {
    case newestFirst = "Newest"
    case oldestFirst = "Oldest"
    case alphabeticalAZ = "A → Z"
    case alphabeticalZA = "Z → A"
    case masteryHigh = "Best known"
    case masteryLow = "Least known"
    case dueSoonest = "Due soon"

    var displayName: LocalizedStringKey {
        switch self {
        case .newestFirst:     return "Newest"
        case .oldestFirst:     return "Oldest"
        case .alphabeticalAZ:  return "A → Z"
        case .alphabeticalZA:  return "Z → A"
        case .masteryHigh:     return "Best known"
        case .masteryLow:      return "Least known"
        case .dueSoonest:      return "Due soon"
        }
    }
}

struct DictionaryView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var selectedTag: String? = nil
    @State private var searchText = ""
    @State private var debouncedSearch = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var sortOption: DictionarySortOption = .newestFirst

    @State private var cachedTag: String? = nil
    @State private var cachedSearch: String = ""
    @State private var cachedSort: DictionarySortOption = .newestFirst
    @State private var cachedRevision: Int = -1
    @State private var cachedFiltered: [StoredWord] = []
    @State private var showAddTag = false
    @State private var isSelectMode = false
    @State private var selectedWordIDs: Set<UUID> = []
    @State private var showBulkDeleteConfirmation = false
    @State private var cardAppeared: Set<UUID> = []
    @AppStorage(AppStorageKeys.hasSeenReactionHint) private var hasSeenReactionHint: Bool = false

    private var filteredWords: [StoredWord] { cachedFiltered }
    private let horizontalPadding: CGFloat = 20

    private var gridColumns: [GridItem] {
        hSize == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    private var headerView: some View {
        HStack {
            Text("Dictionary")
                .font(themeStore.bold(38))
                .foregroundColor(themeStore.mainText)
            Spacer()
            if !store.words.isEmpty {
                Button {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSelectMode.toggle()
                        if !isSelectMode { selectedWordIDs.removeAll() }
                    }
                } label: {
                    Text(isSelectMode ? "Done" : "Select")
                        .font(themeStore.medium(15))
                        .foregroundColor(isSelectMode ? .white : themeStore.mainText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelectMode ? themeStore.mainAccentColor : themeStore.cardBg)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(isSelectMode ? "Done selecting" : "Select words"))
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, horizontalPadding)
    }

    var body: some View {
        Group {
            if store.words.isEmpty {
                VStack(spacing: 0) {
                    headerView

                    EmptyListView(
                        icon: "book.closed",
                        title: "Your word garden is waiting",
                        subtitle: "Add a couple of words and I'll keep them safe here. Little by little — you'll see your vocabulary grow every day."
                    )
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        headerView

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(themeStore.secondaryText)
                            TextField("Search words, translations, examples...", text: $searchText)
                                .font(themeStore.regular(16))
                                .foregroundColor(themeStore.mainText)
                                .disableAutocorrection(true)
                            if !searchText.isEmpty {
                                Button(action: { Haptics.lightImpact(intensity: 0.4); searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(themeStore.secondaryText)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("Clear search"))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(themeStore.cardBg)
                        )
                        .padding(.horizontal, horizontalPadding)

                        TagsView(selectedTag: $selectedTag, onAddTag: { showAddTag = true }, sortOption: $sortOption)
                            .padding(.horizontal, horizontalPadding)

                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            if filteredWords.isEmpty {
                                if let tag = selectedTag, !tag.isEmpty {
                                    EmptyListView(
                                        icon: "tag",
                                        title: "No words in «\(tag)»",
                                        subtitle: "Add words with this tag and they'll appear here."
                                    )
                                    .frame(minHeight: 300)
                                } else if !searchText.isEmpty {
                                    EmptyListView(
                                        icon: "magnifyingglass",
                                        title: "No words found",
                                        subtitle: "Try a different search or remove the filter."
                                    )
                                    .frame(minHeight: 300)
                                }
                            } else {
                                if isSelectMode {
                                    Button {
                                        Haptics.selection()
                                        if selectedWordIDs.count == filteredWords.count {
                                            selectedWordIDs.removeAll()
                                        } else {
                                            selectedWordIDs = Set(filteredWords.map(\.id))
                                        }
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: selectedWordIDs.count == filteredWords.count ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 22))
                                                .foregroundColor(selectedWordIDs.count == filteredWords.count ? themeStore.mainAccentColor : themeStore.secondaryText)
                                            Text("Select all (\(filteredWords.count))")
                                                .font(themeStore.medium(15))
                                                .foregroundColor(themeStore.mainText)
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                }

                                ForEach(Array(filteredWords.enumerated()), id: \.element.id) { index, word in
                                    HStack(spacing: 12) {
                                        if isSelectMode {
                                            Button {
                                                Haptics.lightImpact(intensity: 0.3)
                                                if selectedWordIDs.contains(word.id) {
                                                    selectedWordIDs.remove(word.id)
                                                } else {
                                                    selectedWordIDs.insert(word.id)
                                                }
                                            } label: {
                                                Image(systemName: selectedWordIDs.contains(word.id) ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(selectedWordIDs.contains(word.id) ? themeStore.mainAccentColor : themeStore.secondaryText)
                                            }
                                            .buttonStyle(.plain)
                                            .transition(.move(edge: .leading).combined(with: .opacity))
                                        }

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
                                            reaction: word.reaction,
                                            storedWord: word
                                        ) {
                                            store.remove(word)
                                        } onReaction: { emoji in
                                            store.setReaction(for: word.id, reaction: emoji)
                                            if !hasSeenReactionHint {
                                                withAnimation { hasSeenReactionHint = true }
                                            }
                                        }
                                    }
                                    .opacity(cardAppeared.contains(word.id) ? 1 : 0)
                                    .offset(y: cardAppeared.contains(word.id) ? 0 : 20)
                                    .onAppear {
                                        let delay = Double(min(index, 15)) * 0.04
                                        _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
                                            cardAppeared.insert(word.id)
                                        }
                                    }

                                    if index == 0 && !hasSeenReactionHint {
                                        HStack(spacing: 6) {
                                            Image(systemName: "hand.tap")
                                                .font(.system(size: 13))
                                            Text("Double tap the card to add a reaction")
                                                .font(themeStore.regular(13))
                                        }
                                        .foregroundColor(themeStore.secondaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, -4)
                                        .transition(.opacity)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 40)
                        .id(themeStore.palette)
                    }
                    .iPadContentWidth(1000)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if isSelectMode && !selectedWordIDs.isEmpty {
                Button {
                    Haptics.warning()
                    showBulkDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Delete \(selectedWordIDs.count) words")
                            .font(themeStore.bold(16))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.accentRed)
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if showBulkDeleteConfirmation {
                CustomAlertView(
                    icon: "trash.fill",
                    iconColor: themeStore.accentRed,
                    title: "Delete \(selectedWordIDs.count) words?",
                    message: "This action cannot be undone.",
                    primaryButton: .init(title: "Delete", style: .destructive) {
                        store.removeMultiple(ids: selectedWordIDs)
                        selectedWordIDs.removeAll()
                        isSelectMode = false
                        showBulkDeleteConfirmation = false
                    },
                    secondaryButton: .init(title: "Cancel", style: .cancel) {
                        showBulkDeleteConfirmation = false
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .background(themeStore.appBg)
        .sheet(isPresented: $showAddTag) {
            AddTagView()
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            recalculateFiltered()
        }
        .onChange(of: selectedTag) { cardAppeared.removeAll(); recalculateFiltered() }
        .onChange(of: store.revision) { recalculateFiltered() }
        .onChange(of: searchText) {
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                debouncedSearch = searchText
            }
        }
        .onChange(of: debouncedSearch) { cardAppeared.removeAll(); recalculateFiltered() }
        .onChange(of: sortOption) { cardAppeared.removeAll(); recalculateFiltered() }
        .animation(.spring(), value: store.words.count)
    }

    private func recalculateFiltered() {
        let tag = selectedTag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let search = debouncedSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if tag == cachedTag, search == cachedSearch, sortOption == cachedSort, store.revision == cachedRevision { return }

        var result = store.words

        if !tag.isEmpty {
            result = result.filter {
                ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == tag.lowercased()
            }
        }

        if !search.isEmpty {
            result = result.filter { w in
                if w.word.lowercased().contains(search) { return true }
                if (w.translation ?? "").lowercased().contains(search) { return true }
                if (w.example ?? "").lowercased().contains(search) { return true }
                if (w.explanation ?? "").lowercased().contains(search) { return true }
                if (w.comment ?? "").lowercased().contains(search) { return true }
                if (w.transcription ?? "").lowercased().contains(search) { return true }
                return false
            }
        }

        switch sortOption {
        case .newestFirst:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .oldestFirst:
            result.sort { $0.dateAdded < $1.dateAdded }
        case .alphabeticalAZ:
            result.sort { $0.word.lowercased() < $1.word.lowercased() }
        case .alphabeticalZA:
            result.sort { $0.word.lowercased() > $1.word.lowercased() }
        case .masteryHigh:
            result.sort { $0.repetitions > $1.repetitions }
        case .masteryLow:
            result.sort { $0.repetitions < $1.repetitions }
        case .dueSoonest:
            result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        }

        cachedFiltered = result
        cachedTag = tag
        cachedSearch = search
        cachedSort = sortOption
        cachedRevision = store.revision
    }
}

#Preview {
    DictionaryView()
        .environmentObject(WordsStore())
}
