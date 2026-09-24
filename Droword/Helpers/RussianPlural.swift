import Foundation

enum RussianPlural {
    static func form(count: Int, one: String, few: String, many: String) -> String {
        let n = abs(count) % 100
        let n1 = n % 10
        if n >= 11 && n <= 14 { return many }
        switch n1 {
        case 1: return one
        case 2, 3, 4: return few
        default: return many
        }
    }

    static var prefersRussian: Bool {
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        return preferred.lowercased().hasPrefix("ru")
    }

    static func packsReady(_ count: Int) -> String {
        if prefersRussian {
            let noun = form(count: count, one: "набор", few: "набора", many: "наборов")
            let ready = form(count: count, one: "готов", few: "готовы", many: "готовы")
            return "\(count) \(noun) \(ready)"
        }
        if count == 1 {
            return String(localized: "1 pack ready")
        }
        return String(localized: "\(count) packs ready")
    }
}
