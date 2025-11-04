import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WordsStore

    @State private var word = ""
    @State private var translation = ""
    @State private var comment = ""
    @State private var selectedTag: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }

                Text("Add new word")
                    .font(.custom("Poppins-Bold", size: 38))
                    .foregroundColor(.black)

                FormTextField(
                    title: "Word or phrase *",
                    text: $word,
                    focusedColor: .black,
                    maxLength: 40,
                    showCounter: true
                )

                FormTextField(
                    title: "Translation",
                    text: $translation,
                    focusedColor: .black
                )

                FormTextField(
                    title: "Comment",
                    text: $comment,
                    focusedColor: Color("MainBlack")
                )

                TagsView(selectedTag: $selectedTag)

                Spacer(minLength: 20)

                ActionButton(title: "Add", color: Color("MainBlack")) {
                    let result: GPTTranslationResult
                    if translation.trimmingCharacters(in: .whitespaces).isEmpty {
                        result = try await translateWithGPT(
                            word: word,
                            sourceLang: "Spanish",
                            targetLang: "Russian"
                        )
                    } else {
                        result = GPTTranslationResult(
                            translation: translation,
                            example: "",
                            type: "unknown",
                        )
                    }

                    let newWord = StoredWord(
                        word: word,
                        type: result.type,
                        translation: result.translation,
                        example: result.example,
                        comment: comment,
                        tag: selectedTag
                    )

                    store.add(newWord)
                    word = ""
                    translation = ""
                    comment = ""
                    selectedTag = nil
                } onSuccess: {
                    dismiss()
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    AddWordView().environmentObject(WordsStore())
}
