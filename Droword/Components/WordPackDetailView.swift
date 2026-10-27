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

    var body: some View {
        NavigationStack {
            Group {
                if visibleWords.isEmpty && addedCount > 0 {
                    WordsAddedPage(count: addedCount) {
                        dismiss()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text(pack.titleKey)
                        .sheetTitle()

                    if !visibleWords.isEmpty {
                        HStack {
                            Text("\(visibleWords.count) words")
                                .font(themeStore.bold(20))
                                .foregroundStyle(themeStore.mainText)

                            Spacer()

                            if addedCount > 0 {
                                Text("\(addedCount) added")
                                    .font(themeStore.regular(13))
                                    .foregroundStyle(themeStore.accentBlue)
                            }
                        }

                        if visibleWords.count > 1 {
                            Button {
                                Haptics.lightImpact()
                                addAllWords()
                            } label: {
                                HStack(spacing: 6) {
                                    AddPlusIcon()
                                    Text("Add all")
                                }
                                .duo3DStyle(themeStore.mainAccentColor)
                            }
                            .buttonStyle(Duo3DButtonStyle())
                        }

                        ForEach(visibleWords, id: \.word) { word in
                            SelectableWordCard(
                                word: word.word,
                                translation: word.translation,
                                type: word.type,
                                transcription: word.transcription,
                                example: word.example,
                                explanation: word.explanation,
                                breakdown: word.breakdown,
                                collocations: word.collocations,
                                synonyms: word.synonyms,
                                antonyms: word.antonyms,
                                forms: word.forms,
                                tag: packTag,
                                onAdd: { addWord(word) },
                                onSkip: {
                                    skippedWordIDs.insert(word.word)
                                    checkCompletion()
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    if visibleWords.isEmpty {
                        completionView
                    }
                }
                .padding(.horizontal, DesignSpacing.screenInset)
                .padding(.bottom, 20)
                .iPadContentWidth(600)
                    }
                }
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !(visibleWords.isEmpty && addedCount > 0) {
                        CloseButton()
                    }
                }
            }
        }
        .onAppear {
            detectAlreadyAdded()
        }
    }

    private var completionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(themeStore.accentBlue)

            Text("All done!")
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)

            if addedCount > 0 {
                Text("\(addedCount) words added to your dictionary")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
            } else {
                Text("All words already in your dictionary")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
            }

            Button {
                Haptics.lightImpact()
                dismiss()
            } label: {
                Text("Close")
                    .font(themeStore.medium(16))
                    .foregroundStyle(themeStore.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var packTag: String? {
        WordPacksData.tagName(for: pack.id)
    }

    private func addWord(_ word: StarterWord) {
        if let packTag {
            WordPacksData.ensureTag(packTag)
        }
        let newWord = word.asStoredWord(
            fromLanguage: languageStore.learningLanguage,
            toLanguage: languageStore.nativeLanguage,
            tag: packTag
        )
        store.add(newWord)
        addedWordIDs.insert(word.word)
        addedCount += 1
        if newWord.needsEnrichment {
            NotificationCenter.default.post(name: .triggerEnrichment, object: nil)
        }
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
