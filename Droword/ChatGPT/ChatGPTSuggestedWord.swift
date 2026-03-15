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
        self.id = UUID()
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

private let suggestWorkerURL = "https://droword-api.droword-api.workers.dev"

@MainActor
func fetchSuggestionsWithTopic(
    words: [String],
    languageStore: LanguageStore,
) async throws -> (topic: String?, suggestions: [SuggestedWord]) {
    
    let learningLanguage = languageStore.learningLanguage
    let nativeLanguage = languageStore.nativeLanguage
    let url = URL(string: "\(suggestWorkerURL)/suggest")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "words": words,
        "learningLanguage": learningLanguage,
        "nativeLanguage": nativeLanguage
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        let raw = String(data: data, encoding: .utf8) ?? "No body"
        throw NSError(domain: "Worker", code: -1, userInfo: [NSLocalizedDescriptionKey: raw])
    }

    let container = try JSONDecoder().decode(SuggestionsContainer.self, from: data)
    return (topic: container.topic, suggestions: container.suggestions)
}
