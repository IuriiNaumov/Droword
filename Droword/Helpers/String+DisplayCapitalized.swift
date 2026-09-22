import Foundation

extension String {
    var displayCapitalized: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return self }
        return String(first).uppercased() + trimmed.dropFirst()
    }
}
