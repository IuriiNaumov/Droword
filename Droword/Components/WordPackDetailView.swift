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
                                    Image(systemName: "plus.circle")
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
                    CloseButton()
                }
            }
        }
        .onAppear {
            detectAlreadyAdded()
        }
    }

    private func wordCard(_ word: StarterWord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word.word)
                .font(themeStore.bold(22))
                .foregroundStyle(themeStore.mainText)

            Text(word.translation)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.secondaryText)

            if let transcription = word.transcription, !transcription.isEmpty {
                Text("[\(transcription)]")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))
            }

            Text(word.type)
                .font(themeStore.regular(13))
                .foregroundStyle(themeStore.secondaryText.opacity(0.6))

            if let example = word.example, !example.isEmpty {
                Text(HighlightedExample.make(
                    example: example,
                    word: word.word,
                    baseColor: UIColor(themeStore.secondaryText),
                    highlightColor: UIColor(themeStore.accentGold),
                    baseFont: themeStore.uiFont(size: 16, weight: .regular),
                    highlightFont: themeStore.uiFont(size: 16, weight: .bold)
                ))
                .fixedSize(horizontal: false, vertical: true)
            }

            if let explanation = word.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(themeStore.regular(15))
                    .foregroundStyle(themeStore.mainText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !word.collocations.isEmpty {
                factLine("Common phrases", word.collocations.joined(separator: "  ·  "))
            }
            if !word.synonyms.isEmpty {
                factLine("Synonyms", word.synonyms.joined(separator: "  ·  "))
            }
            if !word.antonyms.isEmpty {
                factLine("Opposites", word.antonyms.joined(separator: "  ·  "))
            }

            HStack {
                Button {
                    withAnimation(.spring()) {
                        addWord(word)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add")
                    }
                    .font(themeStore.medium(13))
                    .foregroundStyle(.white)
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
                    .foregroundStyle(color)
                }
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(color.opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
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

    private func factLine(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(themeStore.medium(13))
                .foregroundStyle(themeStore.secondaryText)
            Text(value)
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.mainText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var packTag: String? {
        switch pack.id {
        case "food": return "Food"
        case "travel": return "Travel"
        case "daily_life": return "Daily life"
        default: return nil
        }
    }

    private func addWord(_ word: StarterWord) {
        let hasCard = !(word.example ?? "").isEmpty && !(word.explanation ?? "").isEmpty
        let newWord = StoredWord(
            word: word.word,
            type: word.type,
            translation: word.translation,
            example: word.example,
            explanation: word.explanation,
            transcription: word.transcription,
            tag: packTag,
            fromLanguage: languageStore.learningLanguage,
            toLanguage: languageStore.nativeLanguage,
            needsEnrichment: !hasCard,
            examples: word.example.map { [$0] } ?? [],
            collocations: word.collocations,
            synonyms: word.synonyms,
            antonyms: word.antonyms
        )
        store.add(newWord)
        addedWordIDs.insert(word.word)
        addedCount += 1
        if !hasCard {
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
