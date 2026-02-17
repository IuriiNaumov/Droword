import Foundation

struct GPTTranslationResult: Codable {
    let translation: String
    let example: String
    let type: String
    let explanation: String?
    let breakdown: String?
}

struct OpenAIResponse: Codable {
    struct Choice: Codable { let message: Message }
    struct Message: Codable { let content: String }
    let choices: [Choice]?
    let error: APIError?
}

struct APIError: Codable {
    let message: String
    let type: String?
}

@MainActor
func translateWithGPT(
    word: String,
    languageStore: LanguageStore
) async throws -> GPTTranslationResult {
    
    let learningLanguage = languageStore.learningLanguage
    let nativeLanguage = languageStore.nativeLanguage

    let url = URL(string: "https://api.openai.com/v1/chat/completions")!


    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let prompt = """
    You are a linguist.

    Translate and explain the word "\(word)".

    Source language: \(learningLanguage)
    Target language: \(nativeLanguage)

    STRICT RULES:
    - translation → only \(nativeLanguage)
    - type → only \(nativeLanguage)
    - explanation → short and clear, only \(nativeLanguage)
    - breakdown → only \(nativeLanguage) or null
    - example → only \(learningLanguage)
    - Do not mix languages inside fields.

    Return ONLY valid JSON:

    {
      "translation": "...",
      "example": "...",
      "type": "...",
      "explanation": "...",
      "breakdown": null or "..."
    }
    """

    let body: [String: Any] = [
        "model": "gpt-4.1-mini",
        "temperature": 0.2,
        "response_format": ["type": "json_object"],
        "messages": [
            ["role": "system", "content": "You always return strictly valid JSON without explanations."],
            ["role": "user", "content": prompt]
        ]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
        let raw = String(data: data, encoding: .utf8) ?? "No body"
        throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: raw])
    }

    let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

    if let err = decoded.error {
        throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: err.message])
    }

    guard let message = decoded.choices?.first?.message.content else {
        let text = String(data: data, encoding: .utf8) ?? "Empty"
        throw NSError(domain: "OpenAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty content or invalid structure"])
    }

    let cleaned = sanitizeJSON(message)
    guard let jsonData = cleaned.data(using: .utf8) else {
        throw NSError(domain: "ChatGPT", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF8"])
    }

    return try JSONDecoder().decode(GPTTranslationResult.self, from: jsonData)
}

private func sanitizeJSON(_ text: String) -> String {
    if let start = text.firstIndex(of: "{"),
       let end = text.lastIndex(of: "}") {
        return String(text[start...end])
    }
    return text
}
