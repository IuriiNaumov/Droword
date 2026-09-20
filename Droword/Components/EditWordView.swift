import SwiftUI

struct EditWordView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @Environment(\.dismiss) private var dismiss

    let word: StoredWord

    @State private var translation: String
    @State private var example: String
    @State private var comment: String
    @State private var type: String
    @State private var selectedTag: String?
    @State private var transcription: String

    init(word: StoredWord) {
        self.word = word
        _translation = State(initialValue: word.translation ?? "")
        _example = State(initialValue: word.example ?? word.examples.first ?? "")
        _comment = State(initialValue: word.comment ?? "")
        _type = State(initialValue: word.type)
        _selectedTag = State(initialValue: word.tag)
        _transcription = State(initialValue: word.transcription ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(word.word)
                        .font(themeStore.bold(28))
                        .foregroundStyle(themeStore.mainText)

                    FormTextField(title: "Translation", text: $translation)
                    FormTextField(title: "Example", text: $example)
                    FormTextField(title: "Transcription", text: $transcription)
                    FormTextField(title: "Type", text: $type)
                    FormTextField(title: "Comment", text: $comment)

                    Text("Tag")
                        .font(themeStore.bold(14))
                        .foregroundStyle(themeStore.secondaryText)

                    TagsView(
                        selectedTag: $selectedTag,
                        hasSuggestedWords: true,
                        showManagementControls: false
                    )

                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .duo3DStyle(themeStore.mainAccentColor)
                    }
                    .buttonStyle(Duo3DButtonStyle())
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func save() {
        Haptics.buttonPress()
        var updated = word
        updated.translation = translation.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedExample = example.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.example = trimmedExample.nilIfEmpty
        if !trimmedExample.isEmpty {
            if updated.examples.isEmpty {
                updated.examples = [trimmedExample]
            } else {
                updated.examples[0] = trimmedExample
            }
        }
        updated.comment = comment.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        updated.type = type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "word"
            : type.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.tag = selectedTag
        updated.transcription = transcription.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        store.update(updated)
        dismiss()
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

#Preview {
    EditWordView(
        word: StoredWord(
            word: "hola",
            type: "interjection",
            translation: "hello",
            example: "¡Hola!",
            fromLanguage: "Español",
            toLanguage: "English"
        )
    )
    .environmentObject(ThemeStore())
    .environmentObject(WordsStore())
}
