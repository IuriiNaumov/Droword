import SwiftUI
import Combine

final class LanguageStore: ObservableObject {
    private static let nativeKey = "nativeLanguage"
    private static let learningKey = "learningLanguage"

    @Published var nativeLanguage: String {
        didSet { UserDefaults.standard.set(nativeLanguage, forKey: Self.nativeKey) }
    }

    @Published var learningLanguage: String {
        didSet { UserDefaults.standard.set(learningLanguage, forKey: Self.learningKey) }
    }

    init() {
        let savedNative = UserDefaults.standard.string(forKey: Self.nativeKey)
        let savedLearning = UserDefaults.standard.string(forKey: Self.learningKey)

        self.nativeLanguage = savedNative ?? "Русский"
        self.learningLanguage = savedLearning ?? "Español"
    }
}
