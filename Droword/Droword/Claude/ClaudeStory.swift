import Foundation

struct StoryResult: Codable {
    let title: String
    let story: String
    let translation: String
    let usedWords: [String]
}

/// Asks the worker to weave a short, level-appropriate story in the learning
/// language out of the given words — comprehensible input built from what the
/// user is already studying.
@MainActor
func generateStory(
    words: [String],
    languageStore: LanguageStore
) async throws -> StoryResult {
    let body: [String: Any] = [
        "words": words,
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]

    var request = try APIClient.makeRequest(endpoint: "story", body: body)
    request.timeoutInterval = 45
    let (data, response) = try await APIClient.perform(request)
    let validated = try APIClient.validateResponse(data, response)
    return try JSONDecoder().decode(StoryResult.self, from: validated)
}
