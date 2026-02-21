import SwiftUI
import Combine

final class LanguageStore: ObservableObject {
    private static let nativeKey = "nativeLanguage"
    private static let learningKey = "learningLanguage"
    private static let learningLevelKey = "learningLevel"
    private static let learningScoreKey = "learningScore"

    @Published var nativeLanguage: String {
        didSet { UserDefaults.standard.set(nativeLanguage, forKey: Self.nativeKey) }
    }

    @Published var learningLanguage: String {
        didSet { UserDefaults.standard.set(learningLanguage, forKey: Self.learningKey) }
    }
    
    @Published var learningLevel: String {
        didSet { UserDefaults.standard.set(learningLevel, forKey: Self.learningLevelKey) }
    }

    @Published var learningScore: Double {
        didSet {
            UserDefaults.standard.set(learningScore, forKey: Self.learningScoreKey)
            let newLevel = Self.mapScoreToLevel(learningScore)
            if learningLevel != newLevel { learningLevel = newLevel }
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let savedNative = defaults.string(forKey: Self.nativeKey)
        let savedLearning = defaults.string(forKey: Self.learningKey)
        let savedLevel = defaults.string(forKey: Self.learningLevelKey)
        let savedScore = defaults.object(forKey: Self.learningScoreKey) as? Double

        let initialScore = savedScore ?? 0.0
        let initialLevel = savedLevel ?? Self.mapScoreToLevel(initialScore)

        self.nativeLanguage = savedNative ?? "Русский"
        self.learningLanguage = savedLearning ?? "Español"
        self.learningLevel = initialLevel
        self.learningScore = initialScore
    }
}

private extension LanguageStore {
    static func mapScoreToLevel(_ score: Double) -> String {
        switch score {
        case ..<0.15: return "A1"
        case ..<0.35: return "A2"
        case ..<0.55: return "B1"
        case ..<0.75: return "B2"
        case ..<0.9:  return "C1"
        default:      return "C2"
        }
    }
}
