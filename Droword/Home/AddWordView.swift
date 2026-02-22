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
            Color(.appBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
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
        }
        .onTapGesture { focusedField = nil }
        .transaction { tx in tx.disablesAnimations = true }
        .onAppear {
            wordPlaceholder = wordPlaceholders.randomElement() ?? "Enter a word"
            translationPlaceholder = translationPlaceholders.randomElement() ?? "Enter translation"
            commentPlaceholder = commentPlaceholders.randomElement() ?? "Enter a comment"

            if !didAppear { didAppear = true }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("New word")
                .font(.custom("Poppins-Bold", size: 26))
                .foregroundColor(.mainBlack)
                .frame(maxWidth: .infinity, alignment: .center)
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
                focusedColor: .mainGrey,
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
                .foregroundColor(Color(.mainGrey))

            FormTextField(
                title: translationPlaceholder,
                text: $translation,
                focusedColor: Color(.mainGrey)
            )
            .focused($focusedField, equals: .translation)
            .onChange(of: translation) { newValue in
                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                if filtered != newValue { translation = filtered }
            }

            Text("Don’t know the translation? I’ll handle it for you")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(Color(.mainGrey).opacity(0.6))
                .padding(.leading, 2)
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comment")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(Color(.mainGrey).opacity(0.9))

            FormTextField(
                title: commentPlaceholder,
                text: $comment,
                focusedColor: Color(.mainGrey)
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

