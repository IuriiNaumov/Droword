import Foundation
import SwiftUI
import Combine

enum LearningGoal: String, CaseIterable, Identifiable, Codable {
    case dailyChat
    case travel
    case work
    case exam
    case school
    case fun

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dailyChat: return "Daily chat"
        case .travel: return "Travel"
        case .work: return "Work"
        case .exam: return "Exam"
        case .school: return "School"
        case .fun: return "Just for fun"
        }
    }

    var localizedTitle: String {
        switch self {
        case .dailyChat: return String(localized: "Daily chat")
        case .travel: return String(localized: "Travel")
        case .work: return String(localized: "Work")
        case .exam: return String(localized: "Exam")
        case .school: return String(localized: "School")
        case .fun: return String(localized: "Just for fun")
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .dailyChat: return "Casual words you actually say"
        case .travel: return "Airports, food, getting around"
        case .work: return "Meetings, email, office life"
        case .exam: return "Formal vocab, precise forms"
        case .school: return "Classes, homework, campus"
        case .fun: return "Memes, shows, whatever sticks"
        }
    }

    var icon: String {
        switch self {
        case .dailyChat: return "bubble.left.and.bubble.right.fill"
        case .travel: return "airplane"
        case .work: return "briefcase.fill"
        case .exam: return "graduationcap.fill"
        case .school: return "book.fill"
        case .fun: return "sparkles"
        }
    }
}

enum LearningTopic: String, CaseIterable, Identifiable, Codable {
    case travel
    case food
    case work
    case movies
    case social
    case dailyLife
    case street

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .travel: return "Travel"
        case .food: return "Food"
        case .work: return "Work"
        case .movies: return "Movies"
        case .social: return "Social"
        case .dailyLife: return "Daily life"
        case .street: return "Street"
        }
    }

    var localizedTitle: String {
        switch self {
        case .travel: return String(localized: "Travel")
        case .food: return String(localized: "Food")
        case .work: return String(localized: "Work")
        case .movies: return String(localized: "Movies")
        case .social: return String(localized: "Social")
        case .dailyLife: return String(localized: "Daily life")
        case .street: return String(localized: "Street")
        }
    }

    var dictionaryTag: String {
        switch self {
        case .travel: return "Travel"
        case .food: return "Food"
        case .work: return "Work"
        case .movies: return "Movie"
        case .social: return "Social media"
        case .dailyLife: return "Daily life"
        case .street: return "Street"
        }
    }

    var emoji: String {
        switch self {
        case .travel: return "✈️"
        case .food: return "🍜"
        case .work: return "💼"
        case .movies: return "🎬"
        case .social: return "📱"
        case .dailyLife: return "🏠"
        case .street: return "🏙️"
        }
    }
}

enum LearningStyle: String, CaseIterable, Identifiable, Codable {
    case mixed
    case listening
    case reading
    case writing
    case speaking

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .mixed: return "Mixed"
        case .listening: return "Ears"
        case .reading: return "Eyes"
        case .writing: return "Hands"
        case .speaking: return "Voice"
        }
    }

    var localizedTitle: String {
        switch self {
        case .mixed: return String(localized: "Mixed")
        case .listening: return String(localized: "Ears")
        case .reading: return String(localized: "Eyes")
        case .writing: return String(localized: "Hands")
        case .speaking: return String(localized: "Voice")
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .mixed: return "A little of everything"
        case .listening: return "Hear it, feel it"
        case .reading: return "See it, decode it"
        case .writing: return "Type it out"
        case .speaking: return "Say it back"
        }
    }

    var icon: String {
        switch self {
        case .mixed: return "square.grid.2x2.fill"
        case .listening: return "ear.fill"
        case .reading: return "eye.fill"
        case .writing: return "pencil.line"
        case .speaking: return "waveform"
        }
    }

    static var selectableCases: [LearningStyle] {
        allCases.filter { $0 != .speaking }
    }
}

@MainActor
final class LearningProfileStore: ObservableObject {
    static let shared = LearningProfileStore()

    @Published var goal: LearningGoal {
        didSet { UserDefaults.standard.set(goal.rawValue, forKey: AppStorageKeys.learningGoal) }
    }

    @Published var topics: Set<LearningTopic> {
        didSet {
            let raw = topics.map(\.rawValue).sorted()
            UserDefaults.standard.set(raw, forKey: AppStorageKeys.learningTopics)
        }
    }

    @Published var style: LearningStyle {
        didSet { UserDefaults.standard.set(style.rawValue, forKey: AppStorageKeys.learningStyle) }
    }

    @Published var hasConfiguredPreferences: Bool {
        didSet { UserDefaults.standard.set(hasConfiguredPreferences, forKey: AppStorageKeys.hasConfiguredLearningPreferences) }
    }

    var preferredTagNames: [String] {
        topics.map(\.dictionaryTag)
    }

    var preferredTopicLabels: [String] {
        topics.map(\.localizedTitle)
    }

    private init() {
        let goalRaw = UserDefaults.standard.string(forKey: AppStorageKeys.learningGoal) ?? LearningGoal.dailyChat.rawValue
        goal = LearningGoal(rawValue: goalRaw) ?? .dailyChat

        let styleRaw = UserDefaults.standard.string(forKey: AppStorageKeys.learningStyle) ?? LearningStyle.mixed.rawValue
        let parsed = LearningStyle(rawValue: styleRaw) ?? .mixed
        style = parsed == .speaking ? .mixed : parsed

        if let stored = UserDefaults.standard.array(forKey: AppStorageKeys.learningTopics) as? [String] {
            topics = Set(stored.compactMap(LearningTopic.init(rawValue:)))
        } else {
            topics = []
        }

        hasConfiguredPreferences = UserDefaults.standard.bool(forKey: AppStorageKeys.hasConfiguredLearningPreferences)
    }

    func toggleTopic(_ topic: LearningTopic) {
        if topics.contains(topic) {
            topics.remove(topic)
        } else if topics.count < 4 {
            topics.insert(topic)
        }
    }

    func markConfigured() {
        hasConfiguredPreferences = true
    }
}
