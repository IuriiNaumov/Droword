import SwiftUI

enum SettingsDestination: Hashable {
    case personalDetails
    case learningPreferences
    case language
    case appearance
    case theme
    case appIcon
    case fontSize
    case voiceAndSpeech
    case haptics
    case notifications
    case dictionary
    case featureFlags
    case privacyPolicy
    case termsOfUse
    case achievements
    case seasonalEffects
    case appCustomization
    case premium
    case whatsNew
}

struct SettingItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: LocalizedStringKey
    var value: String? = nil
    var showProBadge: Bool = false
    var destination: SettingsDestination? = nil
}
