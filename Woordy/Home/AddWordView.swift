import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
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

    var body: some View {
        ZStack {
            Color(.appBackground).ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.mainBlack)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 32) {
                    Text("New word")
                        .font(.custom("Poppins-Bold", size: 38))
                        .foregroundColor(.mainBlack)

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
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation (optional)")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(Color(.mainGrey).opacity(0.9))

                        FormTextField(
                            title: translationPlaceholder,
                            text: $translation,
                            focusedColor: Color(.mainGrey)
                        )
                        .focused($focusedField, equals: .translation)

                        Text("Don’t know the translation? I’ll handle it for you")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(Color(.mainGrey))
                            .padding(.leading, 2)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comment (optional)")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(Color(.mainGrey).opacity(0.9))

                        FormTextField(
                            title: commentPlaceholder,
                            text: $comment,
                            focusedColor: Color(.mainGrey)
                        )
                        .focused($focusedField, equals: .comment)
                    }

                    Group {
                        if didAppear {
                            TagsView(selectedTag: $selectedTag)
                        } else {
                            Color.clear.frame(height: 1)
                        }
                    }

                    AddWordButton(
                        title: isAdding ? "Adding..." : "Add", isDisabled: word.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        await addWord()
                    }
                    .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onTapGesture { focusedField = nil }
        .transaction { tx in tx.disablesAnimations = true }
        .onAppear {
            wordPlaceholder = wordPlaceholders.randomElement() ?? "Enter a word"
            translationPlaceholder = translationPlaceholders.randomElement() ?? "Enter translation"
            commentPlaceholder = commentPlaceholders.randomElement() ?? "Enter a comment"

            _ = UIFont(name: "Poppins-Bold", size: 12)
            _ = UIFont(name: "Poppins-Regular", size: 12)
            if !didAppear { didAppear = true }
        }
    }

    private func addWord() async {
        guard !isAdding else { return }
        isAdding = true

        do {
            let result = try await translateWithGPT(
                word: word,
                sourceLang: "Spanish",
                targetLang: "Russian"
            )

            let russianType = translatePartOfSpeechToRussian(result.type)
            await MainActor.run {
                let newWord = StoredWord(
                    word: word,
                    type: russianType,
                    translation: result.translation,
                    example: result.example,
                    comment: comment,
                    tag: selectedTag
                )
                store.add(newWord)
                dismiss()
            }
        } catch {}

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
}
