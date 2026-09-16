import Foundation

struct StoryResult: Codable {
    let title: String
    let story: String
    let translation: String
    let usedWords: [String]
}

enum StoryWordPicker {
    static func candidates(
        from words: [StoredWord],
        learningLanguage: String,
        preferredTags: [String],
        limit: Int = 5
    ) -> [String] {
        let eligible = words.filter {
            $0.fromLanguage == learningLanguage
                && $0.translation != nil
                && !($0.translation ?? "").isEmpty
                && $0.word.components(separatedBy: .whitespaces).count <= 3
        }
        guard !eligible.isEmpty else { return [] }

        let preferred = Set(preferredTags.map { $0.lowercased() })
        let grouped = Dictionary(grouping: eligible) { ($0.tag ?? "").lowercased() }
        let themed = grouped
            .filter { !$0.key.isEmpty && (preferred.isEmpty || preferred.contains($0.key)) }
            .max { $0.value.count < $1.value.count }?
            .value ?? []

        let pool = themed.count >= 3 ? themed : eligible
        let due = pool.filter { WordDue.isDue(introduced: $0.introduced, dueDate: $0.dueDate) }
        let rest = pool.filter { word in !due.contains(where: { $0.id == word.id }) }
            .sorted { $0.dateAdded > $1.dateAdded }

        var picked: [StoredWord] = []
        for word in due + rest where picked.count < limit {
            if !picked.contains(where: { $0.id == word.id }) {
                picked.append(word)
            }
        }
        return picked.map(\.word)
    }
}

@MainActor
func generateStory(
    words: [String],
    languageStore: LanguageStore,
    goal: String? = nil,
    topics: [String] = []
) async throws -> StoryResult {
    var body: [String: Any] = [
        "words": words,
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]
    if let goal, !goal.isEmpty {
        body["goal"] = goal
    }
    if !topics.isEmpty {
        body["topics"] = topics
    }

    var request = try APIClient.makeRequest(endpoint: "story", body: body)
    request.timeoutInterval = 45
    let (data, response) = try await APIClient.perform(request)
    let validated = try APIClient.validateResponse(data, response)
    return try JSONDecoder().decode(StoryResult.self, from: validated)
}
