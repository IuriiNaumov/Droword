import SwiftUI

enum DictionarySortOption: String, CaseIterable {
    case newestFirst = "Newest"
    case oldestFirst = "Oldest"
    case alphabeticalAZ = "A → Z"
    case alphabeticalZA = "Z → A"
    case masteryHigh = "Best known"
    case masteryLow = "Least known"
    case hardest = "Hardest"
    case dueSoonest = "Due soon"

    var displayName: LocalizedStringKey {
        switch self {
        case .newestFirst:     return "Newest"
        case .oldestFirst:     return "Oldest"
        case .alphabeticalAZ:  return "A → Z"
        case .alphabeticalZA:  return "Z → A"
        case .masteryHigh:     return "Best known"
        case .masteryLow:      return "Least known"
        case .hardest:         return "Hardest"
        case .dueSoonest:      return "Due soon"
        }
    }
}
