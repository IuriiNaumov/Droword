import SwiftUI

enum HighlightedExample {
    static func make(example: String, word: String) -> AttributedString {
        var attr = AttributedString(example)
        if let range = attr.range(of: word, options: .caseInsensitive) {
            attr[range].foregroundColor = UIColor(Color("AccentGold"))
            attr[range].font = .custom("Poppins-Bold", size: 16)
        }
        return attr
    }
}
