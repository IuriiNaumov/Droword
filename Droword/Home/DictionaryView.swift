import SwiftUI

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
                .foregroundStyle(themeStore.mainText)
            Spacer()
            Button {
                Haptics.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSelectMode.toggle()
                    if !isSelectMode { selectedWordIDs.removeAll() }
                }
            } label: {
                Text(isSelectMode ? "Done" : "Select")
                    .font(themeStore.medium(15))
                    .foregroundStyle(store.words.isEmpty ? themeStore.secondaryText : (isSelectMode ? .white : themeStore.mainText))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelectMode ? themeStore.mainAccentColor : (themeStore.isGlass ? Color.clear : themeStore.cardBg))
                    )
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isSelectMode, cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(store.words.isEmpty)
            .opacity(store.words.isEmpty ? 0.5 : 1)
            .accessibilityLabel(Text(isSelectMode ? "Done selecting" : "Select words"))
        }
        .padding(.top, 8)
        .padding(.horizontal, horizontalPadding)
    }

    var body: some View {
        Group {
            if store.words.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        headerView

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(themeStore.secondaryText)
                            TextField("Search words, translations, examples...", text: $searchText)
                                .font(themeStore.regular(16))
                                .foregroundStyle(themeStore.mainText)
                                .disableAutocorrection(true)
                                .disabled(true)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                        )
                        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
                        .padding(.horizontal, horizontalPadding)

                        TagsView(selectedTag: $selectedTag, onAddTag: { showAddTag = true }, sortOption: $sortOption)
                            .padding(.horizontal, horizontalPadding)

                        EmptyListView(
                            icon: "book.closed",
                            title: "Your word garden is waiting",
                            subtitle: "Add a couple of words and I'll keep them safe here. Little by little — you'll see your vocabulary grow every day."
                        )
                    }
                    .iPadContentWidth(1000)
                }
            } else {
                ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        headerView
                            .id("dictionaryTop")

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(themeStore.secondaryText)
                            TextField("Search words, translations, examples...", text: $searchText)
                                .font(themeStore.regular(16))
                                .foregroundStyle(themeStore.mainText)
                                .disableAutocorrection(true)
                            if !searchText.isEmpty {
                                Button(action: { Haptics.lightImpact(intensity: 0.4); searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(themeStore.secondaryText)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("Clear search"))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                        )
                        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
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
                                                .foregroundStyle(selectedWordIDs.count == filteredWords.count ? themeStore.mainAccentColor : themeStore.secondaryText)
                                            Text("Select all (\(filteredWords.count))")
                                                .font(themeStore.medium(15))
                                                .foregroundStyle(themeStore.mainText)
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
                                                    .foregroundStyle(selectedWordIDs.contains(word.id) ? themeStore.mainAccentColor : themeStore.secondaryText)
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
                                        .foregroundStyle(themeStore.secondaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, -4)
                                        .transition(.opacity)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 40)
                        .animation(.spring(), value: store.words.count)
                        .id(themeStore.palette)
                    }
                    .iPadContentWidth(1000)
                }
                .onChange(of: selectedTag) {
                    proxy.scrollTo("dictionaryTop", anchor: .top)
                }
                } // ScrollViewReader
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
                    .foregroundStyle(.white)
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
                .presentationCornerRadius(DesignRadius.dialog)
        }
        .onAppear {
            recalculateFiltered()
        }
        .onChange(of: selectedTag) { recalculateFiltered(); animateCardsIn() }
        .onChange(of: store.revision) { recalculateFiltered() }
        .onChange(of: searchText) {
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                debouncedSearch = searchText
            }
        }
        .onChange(of: debouncedSearch) { recalculateFiltered(); animateCardsIn() }
        .onChange(of: sortOption) { recalculateFiltered(); animateCardsIn() }
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
            // Hardest first: the lower the ease factor, the more the word has
            // been struggled with. Break ties by more lapses.
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
            let delay = Double(min(i, 15)) * 0.04
            _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
                cardAppeared.insert(word.id)
            }
        }
    }
}

#Preview {
    DictionaryView()
        .environmentObject(WordsStore())
}
