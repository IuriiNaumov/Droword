import SwiftUI
import Combine

final class LanguageStore: ObservableObject {
    private static let nativeKey = "nativeLanguage"
    private static let learningKey = "learningLanguage"
    private static let learningLevelKey = "learningLevel"                 // legacy single value + app-group mirror
    private static let levelsByLanguageKey = "learningLevelsByLanguage"    // per-language user selection
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

    /// User-selected proficiency level, stored separately per learning language
    /// (Japanese uses JLPT, Chinese HSK, Korean TOPIK, everything else CEFR).
    @Published private var levelsByLanguage: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(levelsByLanguage) {
                UserDefaults.standard.set(data, forKey: Self.levelsByLanguageKey)
            }
        }
    }

    /// The learning score is an internal EMA used by the SRS/stats. It no longer
    /// drives the displayed level — the user picks that explicitly.
    @Published var learningScore: Double {
        didSet {
            UserDefaults.standard.set(learningScore, forKey: Self.learningScoreKey)
            Self.shared?.set(learningScore, forKey: Self.learningScoreKey)
        }
    }

    private static let shared = UserDefaults(suiteName: appGroupID)

    /// The chosen level for the current learning language (its scale's code,
    /// e.g. "A1", "N5", "HSK1"). Falls back to the easiest level when unset or
    /// when a stored value doesn't belong to the current language's scale.
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

    init() {
        let defaults = UserDefaults.standard
        let savedNative = defaults.string(forKey: Self.nativeKey)
        let savedLearning = defaults.string(forKey: Self.learningKey)
        let savedScore = defaults.object(forKey: Self.learningScoreKey) as? Double

        let native = savedNative ?? "Русский"
        let learning = savedLearning ?? "Español"

        // Load the per-language level map, migrating any legacy single value.
        var dict: [String: String] = [:]
        if let data = defaults.data(forKey: Self.levelsByLanguageKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            dict = decoded
        } else if let legacy = defaults.string(forKey: Self.learningLevelKey) {
            // Seed the current learning language with the legacy level; invalid
            // values (wrong scale) self-heal via the getter's fallback.
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

    /// Keeps the legacy `learningLevel` key (standard + app group) in sync with
    /// the current language's selection, for any external reader (e.g. widget).
    private func syncCurrentLevelMirror() {
        let level = learningLevel
        UserDefaults.standard.set(level, forKey: Self.learningLevelKey)
        Self.shared?.set(level, forKey: Self.learningLevelKey)
    }
}

// MARK: - Proficiency levels

struct LanguageLevel: Identifiable, Equatable {
    let code: String   // canonical CEFR tier sent to the backend: A1…C2
    let label: String  // descriptive name shown to the user
    var id: String { code }
}

/// One descriptive proficiency scale used for every language. The `code` (a
/// CEFR tier) is what the backend receives; the backend then applies any
/// language-specific script rules (e.g. kana-only for a beginner in Japanese)
/// on top of that difficulty tier.
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

    /// Localized descriptive label for a level code (literal keys so they are
    /// extracted for translation).
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
