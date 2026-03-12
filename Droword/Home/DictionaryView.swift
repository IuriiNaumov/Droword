import SwiftUI

enum DictionarySortOption: String, CaseIterable {
    case newestFirst = "Newest"
    case oldestFirst = "Oldest"
    case alphabeticalAZ = "A → Z"
    case alphabeticalZA = "Z → A"
    case masteryHigh = "Best known"
    case masteryLow = "Least known"
    case dueSoonest = "Due soon"
}

struct DictionaryView: View {
    @EnvironmentObject private var store: WordsStore
    @State private var selectedTag: String? = nil
    @State private var isLoading = true

    @State private var searchText = ""
    @State private var sortOption: DictionarySortOption = .newestFirst

    @State private var cachedTag: String? = nil
    @State private var cachedSearch: String = ""
    @State private var cachedSort: DictionarySortOption = .newestFirst
    @State private var cachedWords: [StoredWord] = []
    @State private var cachedFiltered: [StoredWord] = []
    @State private var showAddTag = false
    @State private var isSelectMode = false
    @State private var selectedWordIDs: Set<UUID> = []
    @State private var showBulkDeleteConfirmation = false

    private var filteredWords: [StoredWord] { cachedFiltered }
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Dictionary")
                        .font(.custom("Poppins-Bold", size: 38))
                        .foregroundColor(.mainBlack)
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
                                .font(.custom("Poppins-Medium", size: 15))
                                .foregroundColor(isSelectMode ? .white : .mainBlack)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isSelectMode ? Color.accentBlack : Color.cardBackground)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, horizontalPadding)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.mainGrey)
                    TextField("Search words...", text: $searchText)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.mainBlack)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button(action: { Haptics.lightImpact(intensity: 0.4); searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.mainGrey)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.divider, lineWidth: 1)
                        )
                )
                .padding(.horizontal, horizontalPadding)

                TagsView(selectedTag: $selectedTag, onAddTag: { showAddTag = true }, sortOption: $sortOption)
                    .padding(.horizontal, horizontalPadding)

                LazyVStack(spacing: 8) {
                    if isLoading {
                        Skeleton()
                    } else if filteredWords.isEmpty {
                        VStack {
                            Spacer(minLength: 40)
                            VStack(spacing: 18) {
                                Text(searchText.isEmpty ? "Your word garden is waiting" : "No words found")
                                    .font(.title3.weight(.medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)

                                if searchText.isEmpty {
                                    Text("Add a couple of words and I'll keep them safe here. Little by little — you'll see your vocabulary grow every day.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                } else {
                                    Text("Try a different search or remove the filter.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            Spacer(minLength: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 300)
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
                                        .foregroundColor(selectedWordIDs.count == filteredWords.count ? Color.accentBlack : .mainGrey)
                                    Text("Select all (\(filteredWords.count))")
                                        .font(.custom("Poppins-Medium", size: 15))
                                        .foregroundColor(.mainBlack)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(filteredWords) { word in
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
                                            .foregroundColor(selectedWordIDs.contains(word.id) ? Color.accentBlack : .mainGrey)
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
                                    tag: word.tag
                                ) {
                                    store.remove(word)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 40)
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
                        Text("Delete \(selectedWordIDs.count) word\(selectedWordIDs.count == 1 ? "" : "s")")
                            .font(.custom("Poppins-Bold", size: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red)
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .alert("Delete \(selectedWordIDs.count) word\(selectedWordIDs.count == 1 ? "" : "s")?", isPresented: $showBulkDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                store.removeMultiple(ids: selectedWordIDs)
                selectedWordIDs.removeAll()
                isSelectMode = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showAddTag) {
            AddTagView()
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            recalculateFiltered()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
        .onChange(of: selectedTag) { _ in recalculateFiltered() }
        .onChange(of: store.words) { _ in recalculateFiltered() }
        .onChange(of: searchText) { _ in recalculateFiltered() }
        .onChange(of: sortOption) { _ in recalculateFiltered() }
        .animation(.spring(), value: store.words.count)
    }

    private func recalculateFiltered() {
        let tag = selectedTag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if tag == cachedTag, search == cachedSearch, sortOption == cachedSort, store.words == cachedWords { return }

        var result = store.words

        // Tag filter
        if !tag.isEmpty {
            result = result.filter {
                ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == tag.lowercased()
            }
        }

        // Search filter
        if !search.isEmpty {
            result = result.filter { w in
                w.word.lowercased().contains(search) ||
                (w.translation ?? "").lowercased().contains(search)
            }
        }

        // Sort
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
        cachedWords = store.words
    }
}

#Preview {
    DictionaryView()
        .environmentObject(WordsStore())
}
