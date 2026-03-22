import Foundation

struct GPTTranslationResult: Codable {
    let translation: String
    let example: String
    let type: String
    let explanation: String?
    let breakdown: String?
    let transcription: String?
}

private let workerBaseURL = "https://droword-api.droword-api.workers.dev"
private let workerAppKey = "drw_live_28f9a1c7e5d34b6"

@MainActor
func translateWithGPT(
    word: String,
    languageStore: LanguageStore
) async throws -> GPTTranslationResult {
    
    let learningLanguage = languageStore.learningLanguage
    let nativeLanguage = languageStore.nativeLanguage
    let url = URL(string: "\(workerBaseURL)/translate")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(workerAppKey, forHTTPHeaderField: "X-App-Key")

    let body: [String: Any] = [
        "word": word,
        "learningLanguage": learningLanguage,
        "nativeLanguage": nativeLanguage,
        "level": languageStore.learningLevel
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
        let raw = String(data: data, encoding: .utf8) ?? "No body"
        throw NSError(domain: "Worker", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: raw])
    }

    return try JSONDecoder().decode(GPTTranslationResult.self, from: data)
}

