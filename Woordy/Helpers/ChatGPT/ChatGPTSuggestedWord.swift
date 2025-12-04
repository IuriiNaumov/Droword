import Foundation

struct SuggestedWord: Identifiable, Codable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let type: String?
    let example: String?

    init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        type: String? = nil,
        example: String? = nil
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.type = type
        self.example = example
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.word = try container.decode(String.self, forKey: .word)
        self.translation = try container.decode(String.self, forKey: .translation)
        self.type = try? container.decode(String.self, forKey: .type)
        self.example = try? container.decode(String.self, forKey: .example)
    }
}

struct OpenAISuggestionsResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String?
            let content: String
        }
        let index: Int?
        let message: Message
        let finish_reason: String?
    }

    struct OpenAIError: Codable, Error {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }

    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]?
    let error: OpenAIError?
}

struct SuggestionsContainer: Codable {
    let topic: String?
    let suggestions: [SuggestedWord]
}

@MainActor
func fetchSuggestionsWithTopic(
    words: [String],
    languageStore: LanguageStore
) async throws -> (topic: String?, suggestions: [SuggestedWord]) {
    
    let language = languageStore.learningLanguage
    let translationLanguage = languageStore.nativeLanguage


    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    let wordsList = words.joined(separator: ", ")


    let prompt = """
    You are a vocabulary assistant helping users learn \(language).

    Here is my current list of \(language) words: \(wordsList)

    1. Identify the general topic or theme of these words (for example: food, travel, emotions, everyday life, etc.).
    2. Suggest two NEW \(language) words that:
       - are thematically related to my list,
       - are NOT already in the list,
       - fit the A2–B1 level for language learners,
       - are commonly used in natural conversation.

    For each suggested word, return:
    - "word": the \(language) word,
    - "translation": its translation into \(translationLanguage),
    - "type": part of speech (noun, verb, adjective, etc.),
    - "example": one natural \(language) sentence using that word.

    Respond ONLY with JSON in this format:
    {
      "topic": "string",
      "suggestions": [
        {
          "word": "palabra1",
          "translation": "перевод1",
          "type": "noun",
          "example": "Ejemplo de uso para palabra1."
        },
        {
          "word": "palabra2",
          "translation": "перевод2",
          "type": "verb",
          "example": "Ejemplo de uso para palabra2."
        }
      ]
    }
    """

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = [
        "model": "gpt-4o-mini",
        "temperature": 0.4,
        "response_format": ["type": "json_object"],
        "messages": [
            ["role": "system", "content": "You are a helpful assistant that always responds with valid JSON only."],
            ["role": "user", "content": prompt]
        ]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        let raw = String(data: data, encoding: .utf8) ?? "No body"
        throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: raw])
    }

    let decoded = try JSONDecoder().decode(OpenAISuggestionsResponse.self, from: data)
    guard let content = decoded.choices?.first?.message.content else {
        throw NSError(domain: "OpenAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty content"])
    }

    let cleaned = sanitizeJSONObject(content)
    guard let jsonData = cleaned.data(using: .utf8) else {
        throw NSError(domain: "ChatGPT", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF8"])
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
