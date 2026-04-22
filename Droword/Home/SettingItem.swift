import SwiftUI

enum SettingsDestination: Hashable {
    case personalDetails
    case language
    case appearance
    case theme
    case voiceAndSpeech
    case notifications
    case dictionary
    case featureFlags
    case privacyPolicy
    case achievements
    case seasonalEffects
    case appCustomization
    case premium
    case whatsNew
}

struct SettingItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    var value: String? = nil
    var showProBadge: Bool = false
}
