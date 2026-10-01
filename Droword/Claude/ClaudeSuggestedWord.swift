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
    let collocations: [String]
    let synonyms: [String]
    let antonyms: [String]
    let mnemonic: String?
    let forms: [String]
    let hasFullCard: Bool

    init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        type: String? = nil,
        example: String? = nil,
        explanation: String? = nil,
        breakdown: String? = nil,
        transcription: String? = nil,
        collocations: [String] = [],
        synonyms: [String] = [],
        antonyms: [String] = [],
        mnemonic: String? = nil,
        forms: [String] = [],
        hasFullCard: Bool = false
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.type = type
        self.example = example
        self.explanation = explanation
        self.breakdown = breakdown
        self.transcription = transcription
        self.collocations = collocations
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.mnemonic = mnemonic
        self.forms = forms
        self.hasFullCard = hasFullCard
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
        self.collocations = (try? container.decode([String].self, forKey: .collocations)) ?? []
        self.synonyms = (try? container.decode([String].self, forKey: .synonyms)) ?? []
        self.antonyms = (try? container.decode([String].self, forKey: .antonyms)) ?? []
        self.mnemonic = try? container.decode(String.self, forKey: .mnemonic)
        self.forms = (try? container.decode([String].self, forKey: .forms)) ?? []
        if let flag = try container.decodeIfPresent(Bool.self, forKey: .hasFullCard) {
            self.hasFullCard = flag
        } else {
            self.hasFullCard = container.contains(.collocations)
        }
    }
}

struct SuggestionsContainer: Codable {
    let topic: String?
    let suggestions: [SuggestedWord]
}

@MainActor
func fetchSuggestionsWithTopic(
    words: [String],
    exclude: [String],
    languageStore: LanguageStore,
    preferredTopics: [String] = [],
    learningGoal: String? = nil
) async throws -> (topic: String?, suggestions: [SuggestedWord]) {
    var body: [String: Any] = [
        "words": words,
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]
    if !exclude.isEmpty {
        body["exclude"] = exclude
    }
    if !preferredTopics.isEmpty {
        body["preferredTopics"] = preferredTopics
    }
    if let learningGoal, !learningGoal.isEmpty {
        body["learningGoal"] = learningGoal
    }

    let request = try APIClient.makeRequest(endpoint: "suggest", body: body)
    let (data, response) = try await APIClient.perform(request)
    let validated = try APIClient.validateResponse(data, response)
    let container = try JSONDecoder().decode(SuggestionsContainer.self, from: validated)
    let normalized = container.suggestions.map {
        SuggestedWord(
            id: $0.id,
            word: $0.word.displayCapitalized,
            translation: $0.translation.displayCapitalized,
            type: $0.type,
            example: $0.example,
            explanation: $0.explanation,
            breakdown: $0.breakdown,
            transcription: $0.transcription,
            collocations: $0.collocations,
            synonyms: $0.synonyms,
            antonyms: $0.antonyms,
            mnemonic: $0.mnemonic,
            forms: HighlightedExample.relevantForms(
                $0.forms,
                headword: $0.word,
                texts: [$0.example ?? ""] + $0.collocations
            ),
            hasFullCard: $0.hasFullCard
        )
    }
    return (topic: container.topic, suggestions: normalized)
}
