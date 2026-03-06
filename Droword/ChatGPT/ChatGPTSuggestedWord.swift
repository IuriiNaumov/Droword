import Foundation

enum CEFRLevel: String, CaseIterable, Codable {
    case A1, A2, B1, B2, C1, C2
}

struct SuggestedWord: Identifiable, Codable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let type: String?
    let example: String?
    let explanation: String?
    let breakdown: String?
    let transcription: String?

    init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        type: String? = nil,
        example: String? = nil,
        explanation: String? = nil,
        breakdown: String? = nil,
        transcription: String? = nil
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.type = type
        self.example = example
        self.explanation = explanation
        self.breakdown = breakdown
        self.transcription = transcription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.word = try container.decode(String.self, forKey: .word)
        self.translation = try container.decode(String.self, forKey: .translation)
        self.type = try? container.decode(String.self, forKey: .type)
        self.example = try? container.decode(String.self, forKey: .example)
        self.explanation = try? container.decode(String.self, forKey: .explanation)
        self.breakdown = try? container.decode(String.self, forKey: .breakdown)
        self.transcription = try? container.decode(String.self, forKey: .transcription)
    }
}

struct ClaudeSuggestionsResponse: Codable {
    struct Content: Codable {
        let type: String
        let text: String?
    }

    struct ClaudeError: Codable {
        let type: String
        let message: String
    }

    let id: String?
    let type: String?
    let role: String?
    let content: [Content]?
    let model: String?
    let stop_reason: String?
    let error: ClaudeError?
}

struct SuggestionsContainer: Codable {
    let topic: String?
    let suggestions: [SuggestedWord]
}

@MainActor
func fetchSuggestionsWithTopic(
    words: [String],
    languageStore: LanguageStore,
) async throws -> (topic: String?, suggestions: [SuggestedWord]) {
    
    let learningLanguage = languageStore.learningLanguage
    let nativeLanguage = languageStore.nativeLanguage
    
    let url = URL(string: "https://api.anthropic.com/v1/messages")!
    let wordsList = words.joined(separator: ", ")


    let prompt = """
    You are a vocabulary assistant.

    Learning language: \(learningLanguage)
    Native language: \(nativeLanguage)

    Current words:
    \(wordsList)

    TASK:
    1. Detect the main topic (one short phrase).
    2. Add exactly TWO new words in \(learningLanguage):
       - related to the topic
       - not in the list
       - suitable for A2–B1
       - common in daily use
    - Provide a short example sentence in the learning language.
    - Provide a short one‑sentence explanation in the native language.
    - Provide a brief breakdown/etymology in the native language if relevant (optional).
    - Provide transcription in IPA or a common transcription if relevant (optional).

    STRICT:
    - word and example → only \(learningLanguage)
    - translation, explanation, breakdown → only \(nativeLanguage)
    - transcription → standard IPA or common Latin transcription
    - valid JSON only

    {
      "topic": "string",
      "suggestions": [
        {
          "word": "string",
          "translation": "string",
          "type": "string",
          "example": "string",
          "explanation": "string",
          "breakdown": "string",
          "transcription": "string"
        },
        {
          "word": "string",
          "translation": "string",
          "type": "string",
          "example": "string",
          "explanation": "string",
          "breakdown": "string",
          "transcription": "string"
        }
      ]
    }
    """
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

    let body: [String: Any] = [
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "system": "You always return strictly valid JSON without explanations.",
        "messages": [
            ["role": "user", "content": prompt]
        ]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        let raw = String(data: data, encoding: .utf8) ?? "No body"
        throw NSError(domain: "Claude", code: -1, userInfo: [NSLocalizedDescriptionKey: raw])
    }

    let decoded = try JSONDecoder().decode(ClaudeSuggestionsResponse.self, from: data)
    guard let content = decoded.content?.first(where: { $0.type == "text" })?.text else {
        throw NSError(domain: "Claude", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty content"])
    }

    let cleaned = sanitizeJSONObject(content)
    guard let jsonData = cleaned.data(using: .utf8) else {
        throw NSError(domain: "Claude", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF8"])
    }

    let container = try JSONDecoder().decode(SuggestionsContainer.self, from: jsonData)
    return (topic: container.topic, suggestions: container.suggestions)
}

private func sanitizeJSONObject(_ text: String) -> String {
    if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
        return String(text[start...end])
    }
    return text
}
