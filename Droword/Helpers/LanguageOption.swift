import SwiftUI

struct LanguageOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let flag: String
    let color: Color
}
