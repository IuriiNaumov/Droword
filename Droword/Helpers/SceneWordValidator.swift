import Foundation

enum SceneWordValidator {
    static func used(_ text: String, word: String) -> Bool {
        let hay = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let needle = word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return !needle.isEmpty && hay.contains(needle)
    }

    static func canSend(draft: String, isSending: Bool, isDone: Bool) -> Bool {
        !isSending && !isDone && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
