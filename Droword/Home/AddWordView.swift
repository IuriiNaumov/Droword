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
                                .font(.custom("Poppins-Bold", size: 17))
                                .foregroundColor(.clear)

                            if isAdding {
                                BouncingDotsView()
                            } else {
                                Text("Add")
                                    .font(.custom("Poppins-Bold", size: 17))
                                    .foregroundColor(.white)
                            }
                        }
                        .duo3DStyle(themeStore.mainAccentColor, isDisabled: word.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .buttonStyle(Duo3DButtonStyle())
                    .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
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
                }
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
                    message: "Saved offline — will update when connected",
                    duration: 1.3
                )
                .zIndex(998)
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
            HStack {
                Text("Word or phrase *")
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundColor(themeStore.secondaryText)
                Spacer()
                Text("\(word.count)/40")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.6))
            }

            FormTextField(
                title: wordPlaceholder,
                text: $word,
                maxLength: 40
            )
            .focused($focusedField, equals: .word)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(true)
            .onChange(of: word) { _, newValue in
                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0.isNumber || "'-".contains($0) }
                if filtered != newValue { word = filtered }
            }
        }
    }

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Translation")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(themeStore.secondaryText)

            FormTextField(
                title: translationPlaceholder,
                text: $translation,
            )
            .focused($focusedField, equals: .translation)
            .onChange(of: translation) { _, newValue in
                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0.isNumber || "'-".contains($0) }
                if filtered != newValue { translation = filtered }
            }

            Text("Don’t know the translation? I’ll handle it for you")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(themeStore.secondaryText.opacity(0.6))
                .padding(.leading, 2)
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory hint")
                .font(.custom("Poppins-Regular", size: 18))
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
                addWordOfflineWithToast(trimmedWord)
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
                    toLanguage: languageStore.nativeLanguage
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
            }
        }

        await MainActor.run { isAdding = false }
    }

    private func addWordOffline(_ trimmedWord: String) {
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
        dismiss()
    }

    private func addWordOfflineWithToast(_ trimmedWord: String) {
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
        showOfflineToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }


}

private struct BouncingDotsView: View {
    @State private var phase: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                    .offset(y: dotOffset(for: index))
            }
        }
        .frame(height: 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                phase.toggle()
            }
        }
    }

    private func dotOffset(for index: Int) -> CGFloat {
        // Even dots (0, 2) go up when phase is true, odd (1, 3) go down
        let up = index.isMultiple(of: 2)
        let offset: CGFloat = 5
        if up {
            return phase ? -offset : offset
        } else {
            return phase ? offset : -offset
        }
    }
}

#Preview {
    AddWordView(store: WordsStore())
        .environmentObject(LanguageStore())
}


