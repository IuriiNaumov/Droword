import SwiftUI

struct WordPackDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var store: WordsStore

    let pack: WordPack

    @State private var addedWordIDs: Set<String> = []
    @State private var skippedWordIDs: Set<String> = []
    @State private var alreadyInDictionary: Set<String> = []
    @State private var addedCount = 0

    private var allWords: [StarterWord] {
        WordPacksData.words(
            packID: pack.id,
            learning: languageStore.learningLanguage,
            native: languageStore.nativeLanguage
        ) ?? []
    }

    private var visibleWords: [StarterWord] {
        allWords.filter { word in
            let id = word.word
            return !addedWordIDs.contains(id) && !skippedWordIDs.contains(id) && !alreadyInDictionary.contains(id)
        }
    }

    private var color: Color {
        WordPacksData.packColor(for: pack, themeStore: themeStore)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: pack.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.titleKey)
                                .font(themeStore.bold(22))
                                .foregroundColor(themeStore.mainText)

                            Text(pack.descriptionKey)
                                .font(themeStore.regular(14))
                                .foregroundColor(themeStore.secondaryText)
                        }
                    }

                    if !visibleWords.isEmpty {
                        HStack {
                            Text("\(visibleWords.count) words")
                                .font(themeStore.bold(16))
                                .foregroundColor(themeStore.mainText)

                            Spacer()

                            if addedCount > 0 {
                                Text("\(addedCount) added")
                                    .font(themeStore.regular(13))
                                    .foregroundColor(themeStore.accentGreen)
                            }
                        }

                        // Add all button (only when more than 1 visible)
                        if visibleWords.count > 1 {
                            Button {
                                Haptics.lightImpact()
                                addAllWords()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add all")
                                }
                                .duo3DStyle(color)
                            }
                            .buttonStyle(Duo3DButtonStyle())
                        }

                        ForEach(visibleWords, id: \.word) { word in
                            wordCard(word)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    // Completion state
                    if visibleWords.isEmpty {
                        completionView
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .iPadContentWidth(600)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SettingsBackButton()
                        .environmentObject(themeStore)
                }
            }
        }
        .onAppear {
            detectAlreadyAdded()
        }
    }

    // MARK: - Word Card

    private func wordCard(_ word: StarterWord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word.word)
                .font(themeStore.bold(22))
                .foregroundColor(themeStore.mainText)

            Text(word.translation)
                .font(themeStore.regular(16))
                .foregroundColor(themeStore.secondaryText)

            if let transcription = word.transcription, !transcription.isEmpty {
                Text("/\(transcription)/")
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))
            }

            Text(word.type)
                .font(themeStore.regular(13))
                .foregroundColor(themeStore.secondaryText.opacity(0.6))

            HStack {
                Button {
                    withAnimation(.spring()) {
                        addWord(word)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(themeStore.medium(13))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(color)
                    .clipShape(Capsule())
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut) {
                        skippedWordIDs.insert(word.word)
                        checkCompletion()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("Skip")
                    }
                    .font(themeStore.regular(13))
                    .foregroundColor(color)
                }
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(color.opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(themeStore.accentGreen)

            Text("All done!")
                .font(themeStore.bold(18))
                .foregroundColor(themeStore.mainText)

            if addedCount > 0 {
                Text("\(addedCount) words added to your dictionary")
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText)
            } else {
                Text("All words already in your dictionary")
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText)
            }

            Button {
                Haptics.lightImpact()
                dismiss()
            } label: {
                Text("Close")
                    .duo3DStyle(color)
            }
            .buttonStyle(Duo3DButtonStyle())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Actions

    private func addWord(_ word: StarterWord) {
        let newWord = StoredWord(
            word: word.word,
            type: word.type,
            translation: word.translation,
            example: nil,
            transcription: word.transcription,
            fromLanguage: languageStore.learningLanguage,
            toLanguage: languageStore.nativeLanguage,
            needsEnrichment: true
        )
        store.add(newWord)
        addedWordIDs.insert(word.word)
        addedCount += 1
        checkCompletion()
    }

    private func addAllWords() {
        for word in visibleWords {
            addWord(word)
        }
    }

    private func detectAlreadyAdded() {
        let existingWords = Set(store.words.map { $0.word.lowercased() })
        for word in allWords {
            if existingWords.contains(word.word.lowercased()) {
                alreadyInDictionary.insert(word.word)
            }
        }
        // If all words already handled, auto-mark completed
        if visibleWords.isEmpty {
            markCompleted()
        }
    }

    private func checkCompletion() {
        if visibleWords.isEmpty {
            markCompleted()
        }
    }

    private func markCompleted() {
        WordPackTracker.markCompleted(
            packID: pack.id,
            learning: languageStore.learningLanguage,
            native: languageStore.nativeLanguage
        )
    }
}

#Preview {
    WordPackDetailView(
        pack: WordPacksData.allPacks[0]
    )
    .environmentObject(ThemeStore())
    .environmentObject(LanguageStore())
    .environmentObject(WordsStore())
}
