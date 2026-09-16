import SwiftUI
import Combine

final class LanguageStore: ObservableObject {
    private static let nativeKey = "nativeLanguage"
    private static let learningKey = "learningLanguage"
    private static let learningLevelKey = "learningLevel"
    private static let levelsByLanguageKey = "learningLevelsByLanguage"
    private static let learningScoreKey = "learningScore"

    @Published var nativeLanguage: String {
        didSet {
            UserDefaults.standard.set(nativeLanguage, forKey: Self.nativeKey)
            Self.shared?.set(nativeLanguage, forKey: Self.nativeKey)
        }
    }

    @Published var learningLanguage: String {
        didSet {
            UserDefaults.standard.set(learningLanguage, forKey: Self.learningKey)
            Self.shared?.set(learningLanguage, forKey: Self.learningKey)
            syncCurrentLevelMirror()
        }
    }

    @Published private var levelsByLanguage: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(levelsByLanguage) {
                UserDefaults.standard.set(data, forKey: Self.levelsByLanguageKey)
            }
        }
    }

    @Published var learningScore: Double {
        didSet {
            UserDefaults.standard.set(learningScore, forKey: Self.learningScoreKey)
            Self.shared?.set(learningScore, forKey: Self.learningScoreKey)
        }
    }

    private static let shared = UserDefaults(suiteName: appGroupID)
    private static let cefrOrder = ["A1", "A2", "B1", "B2", "C1", "C2"]

    var learningLevel: String {
        get {
            if let stored = levelsByLanguage[learningLanguage],
               LanguageLevels.levels(for: learningLanguage).contains(where: { $0.code == stored }) {
                return stored
            }
            return LanguageLevels.defaultLevel(for: learningLanguage)
        }
        set {
            levelsByLanguage[learningLanguage] = newValue
            syncCurrentLevelMirror()
        }
    }

    func recordLearningSample(_ sample: Double) {
        learningScore = LearningScore.blend(previous: learningScore, sample: sample)
        considerAutoLevelAdjust()
    }

    private func considerAutoLevelAdjust() {
        let dayKey = AppStorageKeys.lastLevelAdjustDay
        let today = DateFormatting.dayFormatter.string(from: Date())
        if UserDefaults.standard.string(forKey: dayKey) == today { return }

        guard let idx = Self.cefrOrder.firstIndex(of: learningLevel) else { return }

        if learningScore >= 0.78, idx < Self.cefrOrder.count - 1 {
            learningLevel = Self.cefrOrder[idx + 1]
            learningScore = 0.55
            UserDefaults.standard.set(today, forKey: dayKey)
        } else if learningScore <= 0.28, idx > 0 {
            learningLevel = Self.cefrOrder[idx - 1]
            learningScore = 0.45
            UserDefaults.standard.set(today, forKey: dayKey)
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let savedNative = defaults.string(forKey: Self.nativeKey)
        let savedLearning = defaults.string(forKey: Self.learningKey)
        let savedScore = defaults.object(forKey: Self.learningScoreKey) as? Double

        let native = savedNative ?? "Русский"
        let learning = savedLearning ?? "Español"

        var dict: [String: String] = [:]
        if let data = defaults.data(forKey: Self.levelsByLanguageKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            dict = decoded
        } else if let legacy = defaults.string(forKey: Self.learningLevelKey) {

            dict[learning] = legacy
        }

        self.nativeLanguage = native
        self.learningLanguage = learning
        self.levelsByLanguage = dict
        self.learningScore = savedScore ?? 0.0

        Self.shared?.set(nativeLanguage, forKey: Self.nativeKey)
        Self.shared?.set(learningLanguage, forKey: Self.learningKey)
        syncCurrentLevelMirror()
    }

    private func syncCurrentLevelMirror() {
        let level = learningLevel
        UserDefaults.standard.set(level, forKey: Self.learningLevelKey)
        Self.shared?.set(level, forKey: Self.learningLevelKey)
    }
}

struct LanguageLevel: Identifiable, Equatable {
    let code: String
    let label: String
    var id: String { code }
}

enum LanguageLevels {
    static let all: [LanguageLevel] = [
        LanguageLevel(code: "A1", label: "Beginner"),
        LanguageLevel(code: "A2", label: "Elementary"),
        LanguageLevel(code: "B1", label: "Pre-Intermediate"),
        LanguageLevel(code: "B2", label: "Intermediate"),
        LanguageLevel(code: "C1", label: "Upper-Intermediate"),
        LanguageLevel(code: "C2", label: "Advanced"),
    ]

    static func levels(for language: String) -> [LanguageLevel] { all }

    static func defaultLevel(for language: String) -> String { all.first?.code ?? "A1" }

    static func label(forCode code: String, language: String) -> String {
        all.first(where: { $0.code == code })?.label ?? code
    }

    static func localizedLabel(forCode code: String) -> LocalizedStringKey {
        switch code {
        case "A1": return "Beginner"
        case "A2": return "Elementary"
        case "B1": return "Pre-Intermediate"
        case "B2": return "Intermediate"
        case "C1": return "Upper-Intermediate"
        case "C2": return "Advanced"
        default:   return LocalizedStringKey(code)
        }
    }
}
