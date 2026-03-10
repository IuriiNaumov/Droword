import Foundation

struct GPTTranslationResult: Codable {
    let translation: String
    let example: String
    let type: String
    let explanation: String?
    let breakdown: String?
    let transcription: String?
}

struct ClaudeTranslateResponse: Codable {
    struct Content: Codable {
        let type: String
        let text: String?
    }
    struct ClaudeError: Codable {
        let type: String
        let message: String
    }
    let content: [Content]?
    let error: ClaudeError?
}

@MainActor
func translateWithGPT(
    word: String,
    languageStore: LanguageStore
) async throws -> GPTTranslationResult {
    
    let learningLanguage = languageStore.learningLanguage
    let nativeLanguage = languageStore.nativeLanguage
    let url = URL(string: "https://api.anthropic.com/v1/messages")!


    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

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
    - transcription → IPA or phonetic transcription using Latin letters only (ASCII), e.g., /…/ or […], or null
    - Do not mix languages inside fields.

    Return ONLY valid JSON:

    {
      "translation": "...",
      "example": "...",
      "type": "...",
      "explanation": "...",
      "breakdown": null or "...",
      "transcription": null or "..."
    }
    """

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

    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
        let raw = String(data: data, encoding: .utf8) ?? "No body"
        throw NSError(domain: "Claude", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: raw])
    }

    let decoded = try JSONDecoder().decode(ClaudeTranslateResponse.self, from: data)

    if let err = decoded.error {
        throw NSError(domain: "Claude", code: -1, userInfo: [NSLocalizedDescriptionKey: err.message])
    }

    guard let message = decoded.content?.first(where: { $0.type == "text" })?.text else {
        throw NSError(domain: "Claude", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty content"])
    }

    let cleaned = sanitizeJSON(message)
    guard let jsonData = cleaned.data(using: .utf8) else {
        throw NSError(domain: "Claude", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF8"])
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
