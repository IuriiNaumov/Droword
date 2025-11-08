import Foundation

struct GPTTranslationResult: Codable {
    let translation: String
    let example: String
    let type: String
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

func translateWithGPT(
    word: String,
    sourceLang: String = "Spanish",
    targetLang: String = "Russian"
) async throws -> GPTTranslationResult {


 
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let prompt = """
    Translate the word "\(word)" from \(sourceLang) to \(targetLang).
    Respond ONLY as pure JSON, with this structure:
    {
      "translation": "<translated word>",
      "example": "<one natural sentence in \(sourceLang) showing how this word is used, without translation or parentheses>",
      "type": "<part of speech like noun, verb, adjective>"
    }
    """

    let body: [String: Any] = [
        "model": "gpt-4o-mini",
        "temperature": 0.3,
        "messages": [
            ["role": "system", "content": "You are a translation assistant. Output must be valid JSON only."],
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

    do {
        let result = try JSONDecoder().decode(GPTTranslationResult.self, from: jsonData)
        return result
    } catch {
        throw error
    }
}

private func sanitizeJSON(_ text: String) -> String {
    if let start = text.firstIndex(of: "{"),
       let end = text.lastIndex(of: "}") {
        return String(text[start...end])
    }
    return text
}
