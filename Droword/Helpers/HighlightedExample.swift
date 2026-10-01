import SwiftUI

enum HighlightedExample {
    static func make(
        example: String,
        word: String,
        forms: [String] = [],
        baseColor: UIColor = .label,
        highlightColor: UIColor? = nil,
        baseFont: UIFont? = nil,
        highlightFont: UIFont? = nil
    ) -> AttributedString {
        let regular = baseFont ?? UIFont(name: "Poppins-Regular", size: 16)
            ?? .systemFont(ofSize: 16)
        let bold = highlightFont ?? UIFont(name: "Poppins-Bold", size: regular.pointSize)
            ?? .systemFont(ofSize: regular.pointSize, weight: .bold)
        let gold = highlightColor ?? UIColor(Color("AccentGold"))

        var attr = AttributedString(example)
        attr.foregroundColor = baseColor
        attr.font = regular

        let lemma = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lemma.isEmpty else { return attr }

        paintSubstring(lemma, in: example, attr: &attr, color: gold, font: bold)

        for form in forms {
            let needle = form.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !needle.isEmpty else { continue }
            guard !sameWord(needle, lemma) else { continue }
            if needle.contains(where: \.isWhitespace) || !example.contains(where: \.isWhitespace) {
                paintSubstring(needle, in: example, attr: &attr, color: gold, font: bold)
            } else {
                paintTokens(equalTo: needle, in: example, attr: &attr, color: gold, font: bold)
            }
        }

        paintRegularInflections(of: lemma, in: example, attr: &attr, color: gold, font: bold)
        return attr
    }

    static func relevantForms(_ forms: [String]?, headword: String, texts: [String]) -> [String] {
        let blob = texts.joined(separator: "\n")
        var seen: [String] = []
        for form in forms ?? [] {
            let needle = form.trimmingCharacters(in: .whitespacesAndNewlines)
            guard needle.count >= 2, needle.count <= 40 else { continue }
            guard needle.split(whereSeparator: \.isWhitespace).count <= 3 else { continue }
            guard !sameWord(needle, headword) else { continue }
            guard blob.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil else { continue }
            guard !seen.contains(where: { sameWord($0, needle) }) else { continue }
            seen.append(needle)
        }
        return seen
    }

    private static func paintRegularInflections(
        of lemma: String,
        in example: String,
        attr: inout AttributedString,
        color: UIColor,
        font: UIFont
    ) {
        guard example.contains(where: \.isWhitespace) else { return }
        let foldedLemma = folded(lemma)
        guard foldedLemma.count >= 4 else { return }
        let minShared = max(4, foldedLemma.count - 3)

        for token in tokens(in: example) {
            let foldedToken = folded(token.text)
            guard foldedToken != foldedLemma else { continue }
            let shared = sharedPrefixCount(foldedToken, foldedLemma)
            let closeEnding = shared >= 3
                && foldedLemma.count <= 6
                && foldedLemma.count - shared <= 1
                && foldedToken.count - shared <= 1
                && Self.looksLikeInfinitive(foldedLemma)
            let regularEnding = shared >= minShared
                && foldedLemma.count - shared <= 3
                && foldedToken.count <= foldedLemma.count + 3
            guard closeEnding || regularEnding else { continue }
            paint(token.range, in: example, attr: &attr, color: color, font: font)
        }
    }

    private static func paintTokens(
        equalTo needle: String,
        in example: String,
        attr: inout AttributedString,
        color: UIColor,
        font: UIFont
    ) {
        let foldedNeedle = folded(needle)
        for token in tokens(in: example) where folded(token.text) == foldedNeedle {
            paint(token.range, in: example, attr: &attr, color: color, font: font)
        }
    }

    private static func paintSubstring(
        _ needle: String,
        in example: String,
        attr: inout AttributedString,
        color: UIColor,
        font: UIFont
    ) {
        let ns = example as NSString
        var search = NSRange(location: 0, length: ns.length)
        while true {
            let found = ns.range(
                of: needle,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: search
            )
            if found.location == NSNotFound { break }
            if let stringRange = Range(found, in: example) {
                paint(stringRange, in: example, attr: &attr, color: color, font: font)
            }
            let next = found.location + max(found.length, 1)
            if next >= ns.length { break }
            search = NSRange(location: next, length: ns.length - next)
        }
    }

    private static func paint(
        _ range: Range<String.Index>,
        in example: String,
        attr: inout AttributedString,
        color: UIColor,
        font: UIFont
    ) {
        guard let attrRange = Range(range, in: attr) else { return }
        attr[attrRange].foregroundColor = color
        attr[attrRange].font = font
    }

    private struct Token {
        let text: String
        let range: Range<String.Index>
    }

    private static func tokens(in text: String) -> [Token] {
        guard let regex = try? NSRegularExpression(pattern: #"\p{L}[\p{L}\p{M}'’]*"#) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return Token(text: String(text[range]), range: range)
        }
    }

    private static func looksLikeInfinitive(_ foldedLemma: String) -> Bool {
        ["er", "ir", "re", "ar", "or"].contains { foldedLemma.hasSuffix($0) }
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func sameWord(_ lhs: String, _ rhs: String) -> Bool {
        folded(lhs) == folded(rhs)
    }

    private static func sharedPrefixCount(_ lhs: String, _ rhs: String) -> Int {
        var count = 0
        for (left, right) in zip(lhs, rhs) {
            if left != right { break }
            count += 1
        }
        return count
    }
}
