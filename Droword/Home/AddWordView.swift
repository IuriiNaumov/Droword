import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: LanguageStore
    @ObservedObject var store: WordsStore

    @State private var word = ""
    @State private var translation = ""
    @State private var comment = ""
    @State private var selectedTag: String? = nil
    @State private var isAdding = false
    @FocusState private var focusedField: Field?
    @State private var didAppear = false

    @State private var wordPlaceholder = ""
    @State private var translationPlaceholder = ""
    @State private var commentPlaceholder = ""
    @State private var clipboardText: String? = nil

    enum Field { case word, translation, comment }

    private let wordPlaceholders = [
        "Something you heard today?",
        "Add a word you liked",
        "New word to remember",
        "Your word of the day",
        "Learned something cool?"
    ]
    private let translationPlaceholders = [
        "Add translation if you know it",
        "Not sure? Skip for now",
        "Write the meaning here",
        "I can translate it for you"
    ]
    private let commentPlaceholders = [
        "Add a short note",
        "Example or context",
        "How will you remember it?",
        "Use it in a sentence"
    ]


    private var wordCounterText: String {
        "\(min(word.count, 40))/40"
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if let clip = clipboardText, word.isEmpty {
                        Button {
                            Haptics.lightImpact()
                            word = clip
                            clipboardText = nil
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.mainBlack)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Paste from clipboard")
                                        .font(.custom("Poppins-Medium", size: 14))
                                        .foregroundColor(.mainBlack)
                                    Text(clip)
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(.mainGrey)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mainGrey)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.divider, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

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

                    AddWordButton(
                        title: isAdding ? "Adding..." : "Add",
                        isDisabled: word.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        await addWord()
                    }
                    .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .transaction { tx in tx.disablesAnimations = true }
        .onAppear {
            wordPlaceholder = wordPlaceholders.randomElement() ?? "Enter a word"
            translationPlaceholder = translationPlaceholders.randomElement() ?? "Enter translation"
            commentPlaceholder = commentPlaceholders.randomElement() ?? "Enter a comment"

            // Check clipboard for potential word
            if let pasteString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
               !pasteString.isEmpty,
               pasteString.count <= 60,
               !pasteString.contains("\n") {
                clipboardText = pasteString
            }

            if !didAppear { didAppear = true }
        }
    }

    private var header: some View {
        ZStack {
            Text("New word")
                .font(.custom("Poppins-Bold", size: 26))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.mainGrey)
                        .padding(8)
                        .background(Color.mainGrey.opacity(0.12))
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
    }

    private var wordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Word or phrase *")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.mainGrey)

            FormTextField(
                title: wordPlaceholder,
                text: $word,
                maxLength: 40,
                showCounter: true
            )
            .focused($focusedField, equals: .word)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(true)
            .onChange(of: word) { newValue in
                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                if filtered != newValue { word = filtered }
            }
        }
    }

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Translation")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(Color.mainGrey)

            FormTextField(
                title: translationPlaceholder,
                text: $translation,
            )
            .focused($focusedField, equals: .translation)
            .onChange(of: translation) { newValue in
                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                if filtered != newValue { translation = filtered }
            }

            Text("Don’t know the translation? I’ll handle it for you")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(Color.mainGrey.opacity(0.6))
                .padding(.leading, 2)
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comment")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(Color.mainGrey.opacity(0.9))

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

        isAdding = true

        do {
            let result = try await translateWithGPT(word: trimmedWord, languageStore: languageStore)
            let russianType = translatePartOfSpeechToRussian(result.type)

            await MainActor.run {
                let newWord = StoredWord(
                    word: trimmedWord,
                    type: russianType,
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
                dismiss()
            }
        } catch {
            print("⚠️ Translation error: \(error.localizedDescription)")
            // Add the word with user-provided data even when translation fails
            await MainActor.run {
                let newWord = StoredWord(
                    word: trimmedWord,
                    type: "",
                    translation: translation.isEmpty ? nil : translation,
                    example: nil,
                    comment: comment.isEmpty ? nil : comment,
                    tag: selectedTag,
                    fromLanguage: languageStore.learningLanguage,
                    toLanguage: languageStore.nativeLanguage
                )
                store.add(newWord)
                dismiss()
            }
        }

        await MainActor.run { isAdding = false }
    }

    private func translatePartOfSpeechToRussian(_ type: String?) -> String {
        guard let type = type?.lowercased() else { return "" }
        switch type {
        case "verb": return "глагол"
        case "phrase": return "фраза"
        case "noun": return "существительное"
        case "adjective": return "прилагательное"
        case "adverb": return "наречие"
        case "pronoun": return "местоимение"
        case "preposition": return "предлог"
        case "conjunction": return "союз"
        case "interjection": return "междометие"
        case "article": return "артикль"
        default: return type
        }
    }
}

#Preview {
    AddWordView(store: WordsStore())
        .environmentObject(LanguageStore())
}


