import Foundation

enum WordDue {
    static func isDue(introduced: Bool, dueDate: Date?, now: Date = Date()) -> Bool {
        guard introduced, let due = dueDate else { return false }
        return due <= now
    }

    static func isUpcoming(introduced: Bool, dueDate: Date?, now: Date = Date()) -> Bool {
        guard introduced, let due = dueDate else { return false }
        return due > now
    }
}
