import Foundation

struct StoryResult: Codable {
    let title: String
    let story: String
    let translation: String
    let usedWords: [String]
}

struct StorySeed: Codable, Identifiable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let forms: [String]
}

struct StoryQuizAnswer: Codable, Equatable {
    let id: UUID
    let remembered: Bool
}

struct SavedReading: Codable {
    let day: String
    let result: StoryResult
    let seeds: [StorySeed]
    let answers: [StoryQuizAnswer]

    init(day: String, result: StoryResult, seeds: [StorySeed], answers: [StoryQuizAnswer] = []) {
        self.day = day
        self.result = result
        self.seeds = seeds
        self.answers = answers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(String.self, forKey: .day)
        result = try container.decode(StoryResult.self, forKey: .result)
        seeds = try container.decode([StorySeed].self, forKey: .seeds)
        answers = try container.decodeIfPresent([StoryQuizAnswer].self, forKey: .answers) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode(result, forKey: .result)
        try container.encode(seeds, forKey: .seeds)
        try container.encode(answers, forKey: .answers)
    }

    private enum CodingKeys: String, CodingKey {
        case day, result, seeds, answers
    }
}

enum StoryArchive {
    static func today() -> SavedReading? {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.savedReadingStory),
              let saved = try? JSONDecoder().decode(SavedReading.self, from: data),
              saved.day == DateFormatting.todayString else { return nil }
        return saved
    }

    static func save(_ saved: SavedReading) {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: AppStorageKeys.savedReadingStory)
    }
}

enum StoryWordPicker {
    static func candidates(
        from words: [StoredWord],
        learningLanguage: String,
        preferredTags: [String],
        limit: Int = 5
    ) -> [StorySeed] {
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
        return picked.map {
            StorySeed(id: $0.id, word: $0.word, translation: $0.translation ?? "", forms: $0.forms)
        }
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
