import Foundation

struct TranslationResult: Codable {
    let translation: String
    let example: String
    let type: String
    let explanation: String?
    let breakdown: String?
    let transcription: String?
    let examples: [String]?
    let collocations: [String]?
    let synonyms: [String]?
    let antonyms: [String]?
    let mnemonic: String?
}

@MainActor
func translateWithClaude(
    word: String,
    languageStore: LanguageStore
) async throws -> TranslationResult {
    let body: [String: Any] = [
        "word": word,
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]

    let request = try APIClient.makeRequest(endpoint: "translate", body: body)
    let (data, response) = try await APIClient.perform(request)
    let validated = try APIClient.validateResponse(data, response)
    let result = try JSONDecoder().decode(TranslationResult.self, from: validated)
    return TranslationResult(
        translation: result.translation.displayCapitalized,
        example: result.example,
        type: result.type,
        explanation: result.explanation,
        breakdown: result.breakdown,
        transcription: result.transcription,
        examples: result.examples,
        collocations: result.collocations,
        synonyms: result.synonyms,
        antonyms: result.antonyms,
        mnemonic: result.mnemonic
    )
}
