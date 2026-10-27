import Foundation

enum StickerArt: String, CaseIterable, Identifiable {
    case star
    case sparkles
    case wand
    case plus
    case bolt
    case bulb
    case brain
    case flame
    case book
    case calendar
    case flag
    case medal
    case trash
    case offline
    case duplicate
    case check
    case warning
    case swap
    case letters
    case camera
    case speaker
    case chat
    case stack
    case dumbbell
    case chart
    case question
    case tag
    case correct
    case wrong
    case scan
    case addWord
    case palette
    case appIcon
    case sprout
    case herb
    case tree
    case trophy
    case crown
    case diamond
    case target
    case notepad

    var id: String { rawValue }

    init?(badgeEmoji: String) {
        switch badgeEmoji {
        case "🌱": self = .sprout
        case "🌿": self = .herb
        case "🌳": self = .tree
        case "🏆": self = .trophy
        case "👑": self = .crown
        case "💎": self = .diamond
        case "🔥": self = .flame
        case "⚡": self = .bolt
        case "🌟": self = .sparkles
        case "🎯": self = .target
        case "📝": self = .notepad
        case "💡": self = .bulb
        default: return nil
        }
    }

    init?(systemName: String) {
        switch systemName {
        case "sparkle", "star", "star.fill": self = .star
        case "sparkles": self = .sparkles
        case "wand.and.sparkles", "wand.and.stars": self = .wand
        case "plus.circle", "plus.circle.fill": self = .plus
        case "bolt", "bolt.fill": self = .bolt
        case "lightbulb", "lightbulb.fill": self = .bulb
        case "brain.head.profile", "brain": self = .brain
        case "flame", "flame.fill": self = .flame
        case "text.book.closed", "character.book.closed", "book.pages", "book", "book.closed": self = .book
        case "calendar": self = .calendar
        case "flag.checkered", "flag": self = .flag
        case "medal": self = .medal
        case "trash", "trash.fill": self = .trash
        case "wifi.slash": self = .offline
        case "doc.on.doc", "doc.on.doc.fill": self = .duplicate
        case "checkmark.circle", "checkmark": self = .check
        case "exclamationmark.triangle", "exclamationmark.triangle.fill": self = .warning
        case "arrow.left.arrow.right": self = .swap
        case "textformat": self = .letters
        case "camera", "camera.fill": self = .camera
        case "speaker.wave.2", "speaker.wave.2.fill": self = .speaker
        case "bubble.left.and.bubble.right": self = .chat
        case "rectangle.stack": self = .stack
        case "dumbbell": self = .dumbbell
        case "chart.line.uptrend.xyaxis": self = .chart
        case "questionmark", "questionmark.circle": self = .question
        case "tag", "tag.fill": self = .tag
        case "checkmark.circle.fill": self = .correct
        case "xmark.circle", "xmark.circle.fill": self = .wrong
        case "doc.text.viewfinder", "text.viewfinder": self = .scan
        case "text.badge.plus": self = .addWord
        case "paintpalette", "paintpalette.fill": self = .palette
        case "app", "app.badge": self = .appIcon        default: return nil
        }
    }
}
