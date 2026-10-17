import Foundation

enum HomeSoftCover: String, Identifiable, Equatable {
    case firstWords
    case coachMarks
    case studyExtras
    case suggestedIntro
    case proInvite
    case motivationalPaywall

    var id: String { rawValue }

    var priority: Int {
        switch self {
        case .firstWords: return 0
        case .coachMarks: return 1
        case .studyExtras: return 2
        case .suggestedIntro: return 3
        case .proInvite: return 4
        case .motivationalPaywall: return 5
        }
    }
}
