import Foundation

enum BuiltInTag {
    static let suggested = "Suggested"
    static let travel = "Travel"
    static let movie = "Movie"
    static let street = "Street"
    static let socialMedia = "Social media"

    static let allStoredNames: Set<String> = [
        suggested, travel, movie, street, socialMedia
    ]

    static func displayName(_ storedName: String) -> String {
        switch storedName {
        case suggested: return String(localized: "Suggested")
        case travel: return String(localized: "Travel")
        case movie: return String(localized: "Movie")
        case street: return String(localized: "Street")
        case socialMedia: return String(localized: "Social media")
        default: return storedName
        }
    }
}
