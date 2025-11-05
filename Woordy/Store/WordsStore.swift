import Foundation
import Combine

struct StoredWord: Identifiable, Codable, Equatable {
    let id: UUID
    var word: String
    var type: String
    var translation: String?
    var example: String?
    var comment: String?
    var tag: String?

    init(
        id: UUID = UUID(),
        word: String,
        type: String,
        translation: String?,
        example: String?,
        comment: String? = nil,
        tag: String? = nil
    ) {
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
        didSet { saveAsync() }
    }

    private let storageKey = "WordsStore.words"

    init() { loadAsync() }

    func add(_ word: StoredWord) {
        DispatchQueue.main.async {
            self.words.append(word)
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
            guard let data = UserDefaults.standard.data(forKey: self.storageKey) else { return }
            if let decoded = try? JSONDecoder().decode([StoredWord].self, from: data) {
                DispatchQueue.main.async {
                    self.words = decoded
                }
            }
        }
    }

    private func saveAsync() {
        let copy = words
        DispatchQueue.global(qos: .background).async {
            if let data = try? JSONEncoder().encode(copy) {
                UserDefaults.standard.set(data, forKey: self.storageKey)
            }
        }
    }
}
