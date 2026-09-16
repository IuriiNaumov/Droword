import Foundation

enum ClaudeScene {
    @MainActor
    static func nextTurn(
        word: String,
        translation: String,
        languageStore: LanguageStore,
        goal: String?,
        messages: [SceneChatMessage]
    ) async throws -> SceneTurn {
        let payload: [[String: String]] = messages.map {
            ["role": $0.role.rawValue, "text": $0.text]
        }
        var body: [String: Any] = [
            "word": word,
            "translation": translation,
            "learningLanguage": languageStore.learningLanguage,
            "nativeLanguage": languageStore.nativeLanguage,
            "level": languageStore.learningLevel,
            "messages": payload
        ]
        if let goal, !goal.isEmpty {
            body["goal"] = goal
        }

        var request = try APIClient.makeRequest(endpoint: "scene", body: body)
        request.timeoutInterval = 20
        let (data, response) = try await APIClient.perform(request)
        let validated = try APIClient.validateResponse(data, response)
        return try JSONDecoder().decode(SceneTurn.self, from: validated)
    }
}
