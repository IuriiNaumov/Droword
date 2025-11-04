import SwiftUI
import Combine


struct StoredWord: Identifiable, Codable, Equatable {
    let id: UUID
    var word: String
    var type: String
    var translation: String?
    var example: String
    var comment: String?
    var tag: String?

    init(id: UUID = UUID(), word: String,  type: String,  translation: String, example:String,  comment: String? = nil, tag: String? = nil) {
        self.id = id
        self.word = word
        self.type = type
        self.translation = translation
        self.example = example
        self.comment = comment
        self.tag = tag
    }
}

final class WordsStore: ObservableObject {
    @Published private(set) var words: [StoredWord] = [] {
        didSet { save() }
    }

    private let storageKey = "WordsStore.words"

    init() {
        load()
    }

    func add(_ word: StoredWord) {
        words.append(word)
    }

    func remove(_ word: StoredWord) {
        words.removeAll { $0.id == word.id }
    }

    func clear() {
        words.removeAll()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([StoredWord].self, from: data)
            self.words = decoded
        } catch {
            self.words = []
        }
    }
    

    private func save() {
        do {
            let data = try JSONEncoder().encode(words)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // ignore errors for now
        }
    }
}

