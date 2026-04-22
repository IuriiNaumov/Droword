import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    var initialWord: String = ""
    @ObservedObject var store: WordsStore
    @State private var word = ""
    @State private var translation = ""
    @State private var comment = ""
    @State private var selectedTag: String? = nil
    @State private var isAdding = false
    @State private var showOfflineAlert = false
    @State private var showOfflineToast = false
    @State private var showDuplicateAlert = false
    @State private var showErrorToast = false
    @State private var showScanWords = false
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasSeenOfflineAlert) private var hasSeenOfflineAlert: Bool = false
    @FocusState private var focusedField: Field?
    @State private var didAppear = false

    @State private var wordPlaceholder = ""
    @State private var translationPlaceholder = ""
    @State private var commentPlaceholder = ""
    enum Field { case word, translation, comment }

    private let wordPlaceholders: [LocalizedStringResource] = [
        "Something you heard today?",
        "Add a word you liked",
        "New word to remember",
        "Your word of the day",
        "Learned something cool?"
    ]
    private let translationPlaceholders: [LocalizedStringResource] = [
        "Add translation if you know it",
        "Not sure? Skip for now",
        "Write the meaning here",
        "I can translate it for you"
    ]
    private let commentPlaceholders: [LocalizedStringResource] = [
        "Where did you hear it?",
        "What does it remind you of?",
        "A scene from a movie?",
        "Link it to something you know"
    ]


    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("New word")
                        .sheetTitle()

                    wordSection
                    translationSection
                    commentSection
                    Group {
                        if didAppear {
                            TagsView(selectedTag: $selectedTag, showManagementControls: false)
                        } else {
                            Color.clear.frame(height: 1)
                        }
                    }

                    Button {
                        Haptics.lightImpact()
                        Task { await addWord() }
                    } label: {
                        ZStack {
                            // Hidden text to keep consistent button size
                            Text("Add")
                                .font(themeStore.bold(17))
                                .foregroundColor(.clear)

                            if isAdding {
                                BouncingDotsView()
                            } else {
                                Text("Add")
                                    .font(themeStore.bold(17))
                                    .foregroundColor(.white)
                            }
                        }
                        .duo3DStyle(themeStore.mainAccentColor, isDisabled: word.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .buttonStyle(Duo3DButtonStyle())
                    .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                    .accessibilityLabel(Text(isAdding ? "Adding word" : "Add word"))
                    .accessibilityHint(Text("Adds the word to your dictionary"))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .iPadContentWidth(600)
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(isAdding)
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        CloseButtonIcon()
                            .environmentObject(themeStore)
                    }
                    .accessibilityLabel(Text("Close"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Haptics.lightImpact()
                        showScanWords = true
                    } label: {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeStore.mainAccentColor)
                    }
                    .accessibilityLabel(Text("Scan words from photo"))
                }
            }
            .fullScreenCover(isPresented: $showScanWords) {
                ScanWordsView(store: store)
                    .environmentObject(themeStore)
                    .environmentObject(languageStore)
                    .tint(themeStore.mainAccentColor)
                    .transaction { $0.disablesAnimations = true }
            }
        }

        .overlay {
            if showOfflineAlert {
                CustomAlertView(
                    icon: "wifi.slash",
                    iconColor: themeStore.accentRed,
                    title: "No internet connection",
                    message: "The word will be saved and enriched with translation and examples once you're back online.",
                    primaryButton: .init(title: "Add anyway", style: .primary) {
                        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
                        addWordOffline(trimmedWord)
                        hasSeenOfflineAlert = true
                        showOfflineAlert = false
                    },
                    secondaryButton: .init(title: "Cancel", style: .cancel) {
                        showOfflineAlert = false
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .overlay {
            if showDuplicateAlert {
                CustomAlertView(
                    icon: "doc.on.doc",
                    iconColor: themeStore.accentGold,
                    title: "Word already exists",
                    message: "«\(word.trimmingCharacters(in: .whitespacesAndNewlines))» is already in your dictionary.",
                    primaryButton: .init(title: "Got it", style: .primary) {
                        showDuplicateAlert = false
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .overlay(alignment: .top) {
            if showOfflineToast {
                BannerToastView(
                    type: .success,
                    message: String(localized: "Saved offline — will update when connected"),
                    duration: 1.3
                )
                .zIndex(998)
            }
            if showErrorToast {
                BannerToastView(
                    type: .success,
                    message: String(localized: "Saved. Translation will update when available."),
                    duration: 2.0
                )
                .zIndex(997)
            }
        }
        .onAppear {
            wordPlaceholder = String(localized: wordPlaceholders.randomElement() ?? "Enter a word")
            translationPlaceholder = String(localized: translationPlaceholders.randomElement() ?? "Enter translation")
            commentPlaceholder = String(localized: commentPlaceholders.randomElement() ?? "Add a memory hint")

            if !initialWord.isEmpty && word.isEmpty {
                word = initialWord
            }

            if !didAppear { didAppear = true }
        }
    }

    private var wordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Word or phrase *")
                .font(themeStore.regular(18))
                .foregroundColor(themeStore.secondaryText)

            ZStack(alignment: .topLeading) {
                if word.isEmpty {
                    Text(wordPlaceholder)
                        .font(themeStore.regular(16))
                        .foregroundColor(themeStore.secondaryText.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 19)
                }
                TextEditor(text: $word)
                    .focused($focusedField, equals: .word)
                    .font(themeStore.regular(16))
                    .foregroundColor(themeStore.mainText)
                    .tint(themeStore.mainAccentColor)
                    .scrollContentBackground(.hidden)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .frame(minHeight: 56)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.dividerColor.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(focusedField == .word ? themeStore.mainAccentColor : Color.clear, lineWidth: 2)
            )
        }
    }

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Translation")
                .font(themeStore.regular(18))
                .foregroundColor(themeStore.secondaryText)

            FormTextField(
                title: translationPlaceholder,
                text: $translation,
            )
            .focused($focusedField, equals: .translation)

            Text("Don’t know the translation? I’ll handle it for you")
                .font(themeStore.regular(14))
                .foregroundColor(themeStore.secondaryText.opacity(0.6))
                .padding(.leading, 2)
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory hint")
                .font(themeStore.regular(18))
                .foregroundColor(themeStore.secondaryText.opacity(0.9))

            FormTextField(
                title: commentPlaceholder,
                text: $comment,
            )
            .focused($focusedField, equals: .comment)
        }
    }
    
    private func addWord() async {
        guard !isAdding else { return }
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty else { return }

        let isDuplicate = store.words.contains {
            $0.word.lowercased() == trimmedWord.lowercased()
        }
        if isDuplicate {
            showDuplicateAlert = true
            return
        }

        let canUseAI = isPremium || DailyLimitsManager.canTranslate

        guard canUseAI else {
            addWordOffline(trimmedWord)
            return
        }

        guard NetworkMonitor.shared.isConnected else {
            if hasSeenOfflineAlert {
                addWordOffline(trimmedWord, showToast: true)
            } else {
                showOfflineAlert = true
            }
            return
        }

        isAdding = true

        do {
            let result = try await translateWithClaude(word: trimmedWord, languageStore: languageStore)

            if !isPremium {
                DailyLimitsManager.recordTranslation()
            }

            await MainActor.run {
                let examplesArray = result.examples ?? [result.example]
                let newWord = StoredWord(
                    word: trimmedWord,
                    type: result.type.lowercased(),
                    translation: result.translation.isEmpty ? translation : result.translation,
                    example: result.example,
                    explanation: result.explanation,
                    breakdown: result.breakdown,
                    transcription: result.transcription,
                    comment: comment,
                    tag: selectedTag,
                    fromLanguage: languageStore.learningLanguage,
                    toLanguage: languageStore.nativeLanguage,
                    examples: examplesArray
                )
                store.add(newWord)
                if selectedTag != nil { DailyChallengeManager.shared.recordTaggedWordAdded() }
                dismiss()
            }
        } catch {
            #if DEBUG
            print("⚠️ Translation error: \(error.localizedDescription)")
            #endif
            await MainActor.run {
                addWordOffline(trimmedWord)
                showErrorToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showErrorToast = false
                }
            }
        }

        await MainActor.run { isAdding = false }
    }

    private func addWordOffline(_ trimmedWord: String, showToast: Bool = false) {
        let newWord = StoredWord(
            word: trimmedWord,
            type: "",
            translation: translation.isEmpty ? nil : translation,
            example: nil,
            comment: comment.isEmpty ? nil : comment,
            tag: selectedTag,
            fromLanguage: languageStore.learningLanguage,
            toLanguage: languageStore.nativeLanguage,
            needsEnrichment: true
        )
        store.add(newWord)
        if selectedTag != nil { DailyChallengeManager.shared.recordTaggedWordAdded() }
        if showToast {
            showOfflineToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        } else {
            dismiss()
        }
    }


}

#Preview {
    AddWordView(store: WordsStore())
        .environmentObject(LanguageStore())
}


