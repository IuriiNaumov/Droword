import SwiftUI

extension ThemeStore {
    func colorForTag(_ tag: String) -> Color {
        switch tag {
        case "Travel": return accentBlue
        case "Suggested": return accentBlue
        default:
            if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }) {
                return resolvedTagColor(custom.colorHex)
            }
            return secondaryText
        }
    }
}
