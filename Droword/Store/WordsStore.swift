import Foundation
import Combine

struct StoredWord: Identifiable, Codable, Equatable {
    let id: UUID
    var word: String
    var type: String
    var translation: String?
    var example: String?
    var comment: String?
    var explanation: String?
    var breakdown: String?
    var tag: String?
    var dateAdded: Date = Date()
    var fromLanguage: String
    var toLanguage: String

    init(
        id: UUID = UUID(),
        word: String,
        type: String,
        translation: String?,
        example: String?,
        explanation: String? = nil,
        breakdown: String? = nil,
        comment: String? = nil,
        tag: String? = nil,
        dateAdded: Date = Date(),
        fromLanguage: String,
        toLanguage: String
    ) {
        self.id = id
        self.word = word
        self.type = type
        self.translation = translation
        self.example = example
        self.explanation = explanation
        self.breakdown = breakdown
        self.comment = comment
        self.tag = tag
        self.dateAdded = dateAdded
        self.fromLanguage = fromLanguage
        self.toLanguage = toLanguage
    }
}


final class WordsStore: ObservableObject {
    @Published private(set) var words: [StoredWord] = [] {
        didSet { saveAsync() }
    }

    @Published private(set) var totalWordsAdded: Int = 0 {
        didSet { saveAsync() }
    }

    private let storageKey = "WordsStore.words"
    private let totalKey = "WordsStore.totalWordsAdded"

    init() { loadAsync() }

    func add(_ word: StoredWord) {
        DispatchQueue.main.async {
            self.words.append(word)
            self.totalWordsAdded += 1
        }
    }

    func remove(_ word: StoredWord) {
        words.removeAll { $0.id == word.id }
    }

    func clear() {
        words.removeAll()
    }

    private func loadAsync() {
        DispatchQueue.global(qos: .background).async {
            let defaults = UserDefaults.standard

            var decodedWords: [StoredWord] = []
            if let data = defaults.data(forKey: self.storageKey),
               let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) {
                decodedWords = decoded
            }

            let total = defaults.integer(forKey: self.totalKey)

            DispatchQueue.main.async {
                self.words = decodedWords
                self.totalWordsAdded = total
            }
        }
    }

    private func saveAsync() {
        let copy = words
        let total = totalWordsAdded

        DispatchQueue.global(qos: .background).async {
            let defaults = UserDefaults.standard
            if let data = try? JSONEncoder().encode(copy) {
                defaults.set(data, forKey: self.storageKey)
            }
            defaults.set(total, forKey: self.totalKey)
        }
    }
}
