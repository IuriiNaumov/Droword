import Foundation

struct GPTTranslationResult: Codable {
    let translation: String
    let example: String
    let type: String
    let explanation: String?
    let breakdown: String?
    let transcription: String?
}

@MainActor
func translateWithGPT(
    word: String,
    languageStore: LanguageStore
) async throws -> GPTTranslationResult {
    let body: [String: Any] = [
        "word": word,
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]

    let request = try APIClient.makeRequest(endpoint: "translate", body: body)
    let (data, response) = try await URLSession.shared.data(for: request)
    let validated = try APIClient.validateResponse(data, response)
    return try JSONDecoder().decode(GPTTranslationResult.self, from: validated)
}

