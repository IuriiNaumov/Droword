import SwiftUI

struct DictionaryView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var selectedTag: String? = nil
    @State private var searchText = ""
    @State private var debouncedSearch = ""
    @FocusState private var isSearchFocused: Bool
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

    var body: some View {
        dictionaryContent
            .overlay(alignment: .bottom) { bulkDeleteBar }
            .overlay { bulkDeleteAlert }
            .background(themeStore.appBg)
            .sheet(isPresented: $showAddTag) {
                AddTagView()
                    .presentationDetents([.fraction(0.65)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(DesignRadius.dialog)
            }
            .onAppear {
                recalculateFiltered()
                animateCardsIn()
            }
            .onChange(of: selectedTag) {
                isSearchFocused = false
                recalculateFiltered()
                animateCardsIn()
            }
            .onChange(of: store.revision) { recalculateFiltered() }
            .onChange(of: searchText) { debounceSearch() }
            .onChange(of: debouncedSearch) { recalculateFiltered(); animateCardsIn() }
            .onChange(of: sortOption) { recalculateFiltered(); animateCardsIn() }
    }

    @ViewBuilder
    private var dictionaryContent: some View {
        if store.words.isEmpty {
            emptyDictionary
        } else {
            populatedDictionary
        }
    }

    private var emptyDictionary: some View {
        VStack(spacing: 0) {
            dictionaryHeader(showsSelect: false)
                .padding(.bottom, 8)

            ZStack(alignment: .bottom) {
                EmptyListView(
                    illustration: AnyView(CryingEmptyIllustration()),
                    title: DuoChaosCopy.dictionaryGarden().title,
                    subtitle: DuoChaosCopy.dictionaryGarden().subtitle
                )

                Button {
                    NotificationCenter.default.post(name: .openAddWord, object: nil)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add a word")
                    }
                    .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .iPadContentWidth(1000)
    }

    private var populatedDictionary: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                dictionaryChrome

                if showsDictionaryFilterEmpty {
                    dictionaryEmptyFilter
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                        .padding(.bottom, 80)
                } else {
                    wordGrid
                        .padding(.top, 10)
                }
            }
            .iPadContentWidth(1000)
        }
        .scrollClipDisabled()
        .scrollDismissesKeyboard(.immediately)
        .iPadContentWidth(1000)
    }

    private var dictionaryChrome: some View {
        VStack(spacing: 12) {
            dictionaryHeader(showsSelect: true)

            DictionarySearchBar(
                searchText: $searchText,
                isFocused: $isSearchFocused,
                enabled: true
            )

            tagsRow
        }
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func dictionaryHeader(showsSelect: Bool) -> some View {
        HStack {
            Text("Dictionary")
                .zoomerTitle(38)
                .environmentObject(themeStore)
            Spacer()
            if showsSelect {
                selectModeButton
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, horizontalPadding)
    }

    private var selectModeButton: some View {
        let disabled = store.words.isEmpty
        let label = isSelectMode ? String(localized: "Done") : String(localized: "Select")
        let fill: Color = {
            if isSelectMode { return themeStore.mainAccentColor }
            return themeStore.isGlass ? Color.clear : themeStore.cardBg
        }()
        let textColor: Color = {
            if disabled { return themeStore.secondaryText }
            return isSelectMode ? .white : themeStore.mainText
        }()

        return Button {
            Haptics.buttonPress()
            isSearchFocused = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSelectMode.toggle()
                if !isSelectMode { selectedWordIDs.removeAll() }
            }
        } label: {
            Text(label)
                .font(themeStore.bold(15))
                .foregroundStyle(textColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                        .fill(fill)
                )
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isSelectMode, cornerRadius: DesignRadius.large))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .accessibilityLabel(Text(isSelectMode ? "Done selecting" : "Select words"))
    }

    private var tagsRow: some View {
        TagsView(
            selectedTag: $selectedTag,
            hasSuggestedWords: store.words.contains { $0.tag == "Suggested" },
            onAddTag: { showAddTag = true },
            sortOption: $sortOption,
            contentInset: horizontalPadding
        )
    }

    private var wordGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            if isSelectMode {
                selectAllRow
            }
            ForEach(Array(filteredWords.enumerated()), id: \.element.id) { index, word in
                DictionaryWordRow(
                    word: word,
                    index: index,
                    isSelectMode: isSelectMode,
                    isSelected: selectedWordIDs.contains(word.id),
                    hasAppeared: cardAppeared.contains(word.id),
                    showReactionHint: index == 0 && !hasSeenReactionHint,
                    onToggleSelect: { toggleSelection(word.id) },
                    onDelete: { store.remove(word) },
                    onReaction: { emoji in
                        store.setReaction(for: word.id, reaction: emoji)
                        if !hasSeenReactionHint {
                            withAnimation { hasSeenReactionHint = true }
                        }
                    },
                    onAppearCard: { appearCard(word.id, index: index) }
                )
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 40)
        .animation(.spring(), value: store.words.count)
        .id(themeStore.palette)
    }

    private var showsDictionaryFilterEmpty: Bool {
        filteredWords.isEmpty && (
            !(selectedTag ?? "").isEmpty || !searchText.isEmpty
        )
    }

    @ViewBuilder
    private var dictionaryEmptyFilter: some View {
        if let tag = selectedTag, !tag.isEmpty {
            EmptyListView(
                icon: nil,
                title: DuoChaosCopy.dictionaryEmpty(tag: tag).title,
                subtitle: DuoChaosCopy.dictionaryEmpty(tag: tag).subtitle
            )
        } else if !searchText.isEmpty {
            EmptyListView(
                icon: "magnifyingglass",
                title: DuoChaosCopy.dictionaryEmpty(tag: nil).title,
                subtitle: DuoChaosCopy.dictionaryEmpty(tag: nil).subtitle
            )
        }
    }

    private var selectAllRow: some View {
        let allSelected = selectedWordIDs.count == filteredWords.count
        let icon = allSelected ? "checkmark.circle.fill" : "circle"
        let iconColor = allSelected ? themeStore.mainAccentColor : themeStore.secondaryText
        let title = String(localized: "Select all (\(filteredWords.count))")

        return Button {
            Haptics.tick()
            if allSelected {
                selectedWordIDs.removeAll()
            } else {
                selectedWordIDs = Set(filteredWords.map(\.id))
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(themeStore.medium(15))
                    .foregroundStyle(themeStore.mainText)
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bulkDeleteBar: some View {
        if isSelectMode && !selectedWordIDs.isEmpty {
            Button {
                Haptics.error()
                showBulkDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Delete \(selectedWordIDs.count) words")
                }
                .duo3DStyle(Color.accentRed)
            }
            .buttonStyle(Duo3DButtonStyle())
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var bulkDeleteAlert: some View {
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

    private func toggleSelection(_ id: UUID) {
        Haptics.tick()
        if selectedWordIDs.contains(id) {
            selectedWordIDs.remove(id)
        } else {
            selectedWordIDs.insert(id)
        }
    }

    private func appearCard(_ id: UUID, index: Int) {
        let delay = Double(min(index, 15)) * 0.04
        _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
            cardAppeared.insert(id)
        }
    }

    private func debounceSearch() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            debouncedSearch = searchText
        }
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
        case .hardest:
            result.sort {
                if $0.easeFactor != $1.easeFactor { return $0.easeFactor < $1.easeFactor }
                return $0.lapses > $1.lapses
            }
        case .dueSoonest:
            result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        }

        cachedFiltered = result
        cachedTag = tag
        cachedSearch = search
        cachedSort = sortOption
        cachedRevision = store.revision
    }

    private func animateCardsIn() {
        cardAppeared.removeAll()
        for (i, word) in cachedFiltered.enumerated() {
            appearCard(word.id, index: i)
        }
    }

}

private struct DictionarySearchBar: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding
    var enabled: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(themeStore.secondaryText)

            TextField("Search words, translations, examples...", text: $searchText)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.mainText)
                .tint(themeStore.mainAccentColor)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .focused(isFocused)
                .submitLabel(.done)
                .disabled(!enabled)
                .onSubmit { isFocused.wrappedValue = false }

            if isFocused.wrappedValue || !searchText.isEmpty {
                Button {
                    Haptics.softTap()
                    if searchText.isEmpty {
                        isFocused.wrappedValue = false
                    } else {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeStore.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(searchText.isEmpty ? "Dismiss search" : "Clear search"))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused.wrappedValue)
        .padding(.horizontal, 14)
        .padding(.vertical, 19)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                .fill(themeStore.dividerColor.opacity(0.55))
        )
        .padding(.horizontal, 20)
    }
}

private struct DictionaryWordRow: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let word: StoredWord
    let index: Int
    let isSelectMode: Bool
    let isSelected: Bool
    let hasAppeared: Bool
    let showReactionHint: Bool
    let onToggleSelect: () -> Void
    let onDelete: () -> Void
    let onReaction: (String?) -> Void
    let onAppearCard: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if isSelectMode {
                    Button(action: onToggleSelect) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? themeStore.mainAccentColor : themeStore.secondaryText)
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
                    collocations: word.collocations,
                    synonyms: word.synonyms,
                    antonyms: word.antonyms,
                    mnemonic: word.mnemonic,
                    reaction: word.reaction,
                    storedWord: word,
                    onDelete: onDelete,
                    onReaction: onReaction
                )
            }

            if showReactionHint {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 13))
                    Text("Press and hold the card for reactions")
                        .font(themeStore.regular(13))
                }
                .foregroundStyle(themeStore.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, -4)
                .transition(.opacity)
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .zIndex(word.reaction != nil ? 10 : 0)
        .id(word.id)
        .onAppear(perform: onAppearCard)
    }
}

#Preview {
    DictionaryView()
        .environmentObject(WordsStore())
}
