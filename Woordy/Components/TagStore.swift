import SwiftUI
import Combine

struct TagItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}

final class TagStore: ObservableObject {
    
    static let shared = TagStore()
    private init() { load() }

    @Published private(set) var tags: [TagItem] = [] { didSet { save() } }

    private let storageKey = "TagStore.tags"

    func addTag(name: String, colorHex: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHex = normalizeHex(colorHex)
        guard !normalizedName.isEmpty else { return }
        if let idx = tags.firstIndex(where: { $0.name.caseInsensitiveCompare(normalizedName) == .orderedSame }) {
            tags[idx].colorHex = normalizedHex
        } else {
            tags.append(TagItem(name: normalizedName, colorHex: normalizedHex))
        }
    }

    func removeTag(_ tag: TagItem) {
        tags.removeAll { $0.id == tag.id }
    }
    
    func removeTag(named name: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { return }
        if let idx = tags.firstIndex(where: { $0.name.caseInsensitiveCompare(normalizedName) == .orderedSame }) {
            tags.remove(at: idx)
        }
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TagItem].self, from: data) {
            tags = decoded
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(tags) {
            defaults.set(data, forKey: storageKey)
        }
    }

    func normalizeHex(_ hex: String) -> String {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        value = value.filter { "0123456789ABCDEFabcdef".contains($0) }
        if value.count == 3 {
            let chars = Array(value)
            value = String([chars[0], chars[0], chars[1], chars[1], chars[2], chars[2]])
        } else if value.count >= 6 {
            let index = value.index(value.startIndex, offsetBy: 6)
            value = String(value[..<index])
        }
        if value.count < 6 {
            if let lastChar = value.last {
                value = value.padding(toLength: 6, withPad: String(lastChar), startingAt: 0)
            } else {
                value = "000000"
            }
        }
        return "#" + value.uppercased()
    }
}

extension Color {
    init?(fromHexString hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let num = UInt64(value, radix: 16) else { return nil }
        let r = Double((num >> 16) & 0xFF) / 255.0
        let g = Double((num >> 8) & 0xFF) / 255.0
        let b = Double(num & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
