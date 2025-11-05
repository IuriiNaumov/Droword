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

    enum Field { case word, translation, comment }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 28) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.black)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 28) {
                    Text("Add new word")
                        .font(.custom("Poppins-Bold", size: 38))
                        .foregroundColor(.black)

                    // Fields
                    FormTextField(
                        title: "Word or phrase *",
                        text: $word,
                        focusedColor: .black,
                        maxLength: 40,
                        showCounter: true
                    )
                    .focused($focusedField, equals: .word)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                    FormTextField(
                        title: "Translation",
                        text: $translation,
                        focusedColor: .black
                    )
                    .focused($focusedField, equals: .translation)

                    FormTextField(
                        title: "Comment (optional)",
                        text: $comment,
                        focusedColor: Color("MainBlack")
                    )
                    .focused($focusedField, equals: .comment)

                    Group {
                        if didAppear {
                            TagsView(selectedTag: $selectedTag)
                        } else {
                            Color.clear.frame(height: 1)
                        }
                    }

                    AddWordButton(
                        title: isAdding ? "Adding..." : "Add",
                        color: .black,
                        isDisabled: word.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        await addWord()
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onTapGesture { focusedField = nil }
        .transaction { tx in
            tx.disablesAnimations = true
        }
        .onAppear {
            // Prewarm custom fonts to avoid first-render stalls
            let _ = UIFont(name: "Poppins-Bold", size: 12)
            let _ = UIFont(name: "Poppins-Regular", size: 12)
            // Mark first appearance so we can defer heavy subviews
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

            await MainActor.run {
                let newWord = StoredWord(
                    word: word,
                    type: result.type,
                    translation: result.translation,
                    example: result.example,
                    comment: comment,
                    tag: selectedTag
                )
                store.add(newWord)
                dismiss()
            }
        } catch {
            print("❌ Translation error:", error.localizedDescription)
        }

        await MainActor.run { isAdding = false }
    }
}

#Preview {
    AddWordView(store: WordsStore())
}
