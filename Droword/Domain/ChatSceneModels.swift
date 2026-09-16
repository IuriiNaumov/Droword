import Foundation

struct SceneTurn: Codable, Equatable {
    let reply: String
    let hint: String?
    let nudge: String?
    let usedWord: Bool
    let done: Bool

    init(reply: String, hint: String?, nudge: String?, usedWord: Bool, done: Bool) {
        self.reply = reply
        self.hint = hint
        self.nudge = nudge
        self.usedWord = usedWord
        self.done = done
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reply = (try c.decodeIfPresent(String.self, forKey: .reply) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        hint = Self.clean(try c.decodeIfPresent(String.self, forKey: .hint))
        nudge = Self.clean(try c.decodeIfPresent(String.self, forKey: .nudge))
        usedWord = try c.decodeIfPresent(Bool.self, forKey: .usedWord) ?? false
        done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
    }

    private static func clean(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "null" { return nil }
        return trimmed
    }
}

struct SceneChatMessage: Equatable, Identifiable {
    enum Role: String {
        case assistant
        case user
    }

    let id: UUID
    let role: Role
    let text: String
    var hint: String? = nil
    var nudge: String? = nil
    var usedWord: Bool = false

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        hint: String? = nil,
        nudge: String? = nil,
        usedWord: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.hint = hint
        self.nudge = nudge
        self.usedWord = usedWord
    }
}

struct ChatSceneTarget: Identifiable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let example: String?
}

enum SceneKind {
    case greeting, farewell, thanks, apology, howAreYou, please, generic

    static func detect(word: String, translation: String) -> SceneKind {
        let hay = "\(word) \(translation)"
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        let parts = hay.split { !$0.isLetter && !$0.isNumber }.map(String.init)

        func has(_ stems: [String]) -> Bool {
            stems.contains { stem in
                if stem.count <= 2 {
                    return parts.contains(stem)
                }
                return hay.contains(stem)
            }
        }

        if has(["hola", "hello", "bonjour", "hallo", "buongiorno", "привет", "здравств", "안녕", "안녕하세요", "こんにちは", "おはよう", "你好", "hey", "hi", "salut", "guten tag", "buenos dias", "bom dia"]) {
            return .greeting
        }
        if has(["goodbye", "bye", "adios", "au revoir", "tschuss", "пока", "прощай", "さようなら", "再见", "farewell"]) {
            return .farewell
        }
        if has(["thanks", "thank you", "gracias", "merci", "danke", "spasibo", "спасибо", "고마워", "감사합니다", "ありがとう", "谢谢"]) {
            return .thanks
        }
        if has(["sorry", "pardon", "lo siento", "entschuldigung", "извини", "прости", "미안", "ごめん", "对不起", "excuse"]) {
            return .apology
        }
        if has(["how are you", "que tal", "como estas", "ca va", "wie geht", "как дела", "어때", "元気", "你好吗"]) {
            return .howAreYou
        }
        if has(["please", "por favor", "s'il te plait", "bitte", "пожалуйста", "부탁", "ください", "请"]) {
            return .please
        }
        return .generic
    }
}
