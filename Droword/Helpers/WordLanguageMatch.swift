import Foundation

enum WordLanguageMatch {
    static func catalogName(for raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "null" else { return nil }
        return LanguageCatalog.availableLanguages.first {
            $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }?.name
    }

    static func guess(word: String, learningLanguage: String) -> String? {
        let letters = Array(word.unicodeScalars).filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 2 else { return nil }

        let guessed: String?
        if contains(letters, in: 0xAC00...0xD7AF) || contains(letters, in: 0x1100...0x11FF) {
            guessed = "한국어"
        } else if contains(letters, in: 0x3040...0x30FF) {
            guessed = "日本語"
        } else if contains(letters, in: 0x4E00...0x9FFF) {
            guessed = learningLanguage == "日本語" ? nil : "中文"
        } else if contains(letters, in: 0x0600...0x06FF) {
            guessed = "العربية"
        } else if contains(letters, in: 0x0590...0x05FF) {
            guessed = "עברית"
        } else if contains(letters, in: 0x0E00...0x0E7F) {
            guessed = "ไทย"
        } else if contains(letters, in: 0x0900...0x097F) {
            guessed = "हिन्दी"
        } else if contains(letters, in: 0x0370...0x03FF) {
            guessed = "Ελληνικά"
        } else if contains(letters, in: 0x0400...0x04FF) {
            let ukrainian: Set<Unicode.Scalar> = ["і", "ї", "є", "ґ", "І", "Ї", "Є", "Ґ"]
            if letters.contains(where: { ukrainian.contains($0) }) {
                guessed = "Українська"
            } else if learningLanguage == "Русский" || learningLanguage == "Українська" {
                guessed = nil
            } else {
                guessed = "Русский"
            }
        } else {
            guessed = nil
        }

        guard let guessed, guessed != learningLanguage else { return nil }
        return guessed
    }

    private static func contains(_ letters: [Unicode.Scalar], in range: ClosedRange<UInt32>) -> Bool {
        letters.contains { range.contains($0.value) }
    }
}
