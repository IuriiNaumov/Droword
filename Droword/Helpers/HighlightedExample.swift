import SwiftUI

enum HighlightedExample {
    static func make(
        example: String,
        word: String,
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

        let needle = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return attr }

        let ns = example as NSString
        var search = NSRange(location: 0, length: ns.length)
        while true {
            let found = ns.range(
                of: needle,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: search
            )
            if found.location == NSNotFound { break }
            if let stringRange = Range(found, in: example),
               let attrRange = Range(stringRange, in: attr) {
                attr[attrRange].foregroundColor = gold
                attr[attrRange].font = bold
            }
            let next = found.location + max(found.length, 1)
            if next >= ns.length { break }
            search = NSRange(location: next, length: ns.length - next)
        }
        return attr
    }
}
