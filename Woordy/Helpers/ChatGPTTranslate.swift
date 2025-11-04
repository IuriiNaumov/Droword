import Foundation
import Foundation

struct GPTTranslationResult: Codable {
    let translation: String
    let example: String
    let type: String
}

func translateWithGPT(
    word: String,
    sourceLang: String = "Spanish",
    targetLang: String = "Russian"
) async throws -> GPTTranslationResult {

    let apiKey = "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"
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

    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)

    guard let content = decoded.choices.first?.message.content else {
        throw NSError(domain: "ChatGPT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty content"])
    }

    let cleaned = sanitizeJSON(content)

    guard let jsonData = cleaned.data(using: .utf8) else {
        throw NSError(domain: "ChatGPT", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF8"])
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

struct OpenAIResponse: Codable {
    struct Choice: Codable { let message: Message }
    struct Message: Codable { let content: String }
    let choices: [Choice]
}
