import SwiftUI

private var _tagColorCache: [String: String?] = [:]
private var _tagColorCacheRevision: Int = -1

extension ThemeStore {
    func colorForTag(_ tag: String) -> Color {
        switch tag {
        case "Travel": return accentBlue
        case "Movie": return accentPink
        case "Street": return accentPurple
        case "Social media": return accentGold
        case "Suggested": return accentBlue
        default:
            let store = TagStore.shared
            let currentRevision = store.tags.count
            if currentRevision != _tagColorCacheRevision {
                _tagColorCache = [:]
                for item in store.tags {
                    _tagColorCache[item.name.lowercased()] = item.colorHex
                }
                _tagColorCacheRevision = currentRevision
            }
            if let hex = _tagColorCache[tag.lowercased()] {
                return resolvedTagColor(hex)
            }
            return secondaryText
        }
    }
}
