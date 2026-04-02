import Foundation

enum CEFRLevel: String, CaseIterable, Codable {
    case A1, A2, B1, B2, C1, C2
}

struct SuggestedWord: Identifiable, Codable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let type: String?
    let example: String?
    let explanation: String?
    let breakdown: String?
    let transcription: String?

    init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        type: String? = nil,
        example: String? = nil,
        explanation: String? = nil,
        breakdown: String? = nil,
        transcription: String? = nil
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.type = type
        self.example = example
        self.explanation = explanation
        self.breakdown = breakdown
        self.transcription = transcription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.word = try container.decode(String.self, forKey: .word)
        self.translation = try container.decode(String.self, forKey: .translation)
        self.type = try? container.decode(String.self, forKey: .type)
        self.example = try? container.decode(String.self, forKey: .example)
        self.explanation = try? container.decode(String.self, forKey: .explanation)
        self.breakdown = try? container.decode(String.self, forKey: .breakdown)
        self.transcription = try? container.decode(String.self, forKey: .transcription)
    }
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
    let body: [String: Any] = [
        "words": words,
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]

    let request = try APIClient.makeRequest(endpoint: "suggest", body: body)
    let (data, response) = try await URLSession.shared.data(for: request)
    let validated = try APIClient.validateResponse(data, response)
    let container = try JSONDecoder().decode(SuggestionsContainer.self, from: validated)
    return (topic: container.topic, suggestions: container.suggestions)
}
