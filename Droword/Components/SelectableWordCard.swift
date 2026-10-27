import SwiftUI

struct SelectableWordCard: View {
    let word: String
    let translation: String
    var type: String? = nil
    var transcription: String? = nil
    var example: String? = nil
    var explanation: String? = nil
    var breakdown: String? = nil
    var collocations: [String] = []
    var synonyms: [String] = []
    var antonyms: [String] = []
    var forms: [String] = []
    var tag: String? = nil
    var isAdding: Bool = false
    let onAdd: () -> Void
    let onSkip: () -> Void

    var body: some View {
        WordCardView(
            word: word,
            translation: translation,
            type: type,
            example: example,
            transcription: transcription,
            comment: nil,
            explanation: explanation,
            breakdown: breakdown,
            tag: tag,
            collocations: collocations,
            synonyms: synonyms,
            antonyms: antonyms,
            forms: forms,
            isAdding: isAdding,
            onAdd: onAdd,
            onSkip: onSkip
        )
    }
}

#Preview {
    SelectableWordCard(
        word: "Hello",
        translation: "Привет",
        type: "междометие",
        transcription: "həˈloʊ",
        example: "Hello, how are you today?",
        explanation: "Так здороваются в любой ситуации.",
        collocations: ["say hello", "hello there"],
        synonyms: ["hi", "hey"],
        antonyms: ["goodbye"],
        onAdd: {},
        onSkip: {}
    )
    .padding()
    .environmentObject(ThemeStore())
    .environmentObject(WordsStore())
}
