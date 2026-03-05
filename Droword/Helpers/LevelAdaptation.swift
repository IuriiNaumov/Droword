import Foundation

struct LevelAdaptation {
    static func adaptExample(_ example: String, targetLanguage: String, level: CEFRLevel) -> String {
        switch targetLanguage {
        case "日本語", "Japanese", "日本語 (Japanese)":
            return adaptJapanese(example, level: level)
        case "中文", "汉语", "Chinese", "中文 (Chinese)":
            return adaptChinese(example, level: level)
        default:
            return adaptGeneric(example, level: level)
        }
    }

    private static func adaptJapanese(_ s: String, level: CEFRLevel) -> String {
        switch level {
        case .A1, .A2:
            let scalars = s.unicodeScalars.map { scalar -> Character in
                if isCJKIdeograph(scalar) {
                    return "•"
                } else {
                    return Character(scalar)
                }
            }
            let masked = String(scalars)
            return shortenIfTooLong(masked, maxChars: 45)
        default:
            return s
        }
    }

    private static func adaptChinese(_ s: String, level: CEFRLevel) -> String {
        switch level {
        case .A1, .A2:
            let scalars = s.unicodeScalars.map { scalar -> Character in
                if isCJKIdeograph(scalar) {
                    return "•"
                } else {
                    return Character(scalar)
                }
            }
            let masked = String(scalars)
            return shortenIfTooLong(masked, maxChars: 45)
        default:
            return s
        }
    }

    private static func adaptGeneric(_ s: String, level: CEFRLevel) -> String {
        switch level {
        case .A1:
            return shortenIfTooLong(simplifyPunctuation(s), maxChars: 60)
        case .A2:
            return shortenIfTooLong(s, maxChars: 80)
        default:
            return s
        }
    }

    private static func isCJKIdeograph(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x4E00...0x9FFF, // CJK Unified Ideographs
             0x3400...0x4DBF, // CJK Unified Ideographs Extension A
             0x20000...0x2A6DF, // Extension B
             0x2A700...0x2B73F, // Extension C
             0x2B740...0x2B81F, // Extension D
             0x2B820...0x2CEAF, // Extension E
             0x2CEB0...0x2EBEF: // Extension F
            return true
        default:
            return false
        }
    }

    private static func simplifyPunctuation(_ s: String) -> String {
        var result = s.replacingOccurrences(of: ",", with: ") ")
        result = result.replacingOccurrences(of: ";", with: ". ")
        return result
    }

    private static func shortenIfTooLong(_ s: String, maxChars: Int) -> String {
        guard s.count > maxChars else { return s }
        let end = s.index(s.startIndex, offsetBy: maxChars)
        return String(s[..<end]) + "…"
    }
}

