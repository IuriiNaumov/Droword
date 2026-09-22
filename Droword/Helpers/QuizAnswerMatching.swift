import Foundation

enum QuizAnswerMatching {
    static func normalize(_ string: String) -> String {
        let lowered = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")

        return lowered.filter { !$0.isWhitespace }
    }

    static func isExactMatch(_ input: String, expected: String) -> Bool {
        normalize(input) == normalize(expected)
    }

    static func isAlmostMatch(_ input: String, expected: String) -> Bool {
        let a = normalize(input)
        let b = normalize(expected)
        guard !a.isEmpty, !b.isEmpty, a != b else { return false }
        let dist = levenshteinDistance(a, b)
        let threshold = max(1, b.count / 4)
        return dist <= threshold
    }
}
