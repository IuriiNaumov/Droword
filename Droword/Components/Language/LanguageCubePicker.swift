import SwiftUI
import UIKit

struct LanguageCubePicker: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Binding var selectedLanguage: String
    var title: LocalizedStringKey
    var languages: [LanguageOption]
    var blockedLanguage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(themeStore.bold(18))
                .foregroundStyle(.primary)
                .padding(.horizontal)

            FlowLayout(spacing: 12) {
                ForEach(Array(languages.enumerated()), id: \.element.id) { index, lang in
                    let isBlocked = lang.name == blockedLanguage
                    SelectionChip(
                        title: LocalizedStringKey(lang.name),
                        leading: lang.flag,
                        color: themeStore.isMonochrome ? themeStore.monoDark : Self.palette(themeStore)[index % 3],
                        isSelected: selectedLanguage == lang.name,
                        isDisabled: isBlocked,
                        verticalPadding: 15,
                        horizontalPadding: 38,
                        titleFontSize: 16
                    ) {
                        selectedLanguage = lang.name
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }

    /// Three rotating accent colours (like the dictionary tags) so the language
    /// chips aren't all one colour.
    private static func palette(_ themeStore: ThemeStore) -> [Color] {
        [themeStore.accentBlue, themeStore.accentPink, themeStore.accentGold]
    }
}

/// Horizontal chips for picking the learner's proficiency level. The scale
/// adapts to the current learning language (CEFR / JLPT / HSK / TOPIK).
struct LanguageLevelPicker: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore

    var title: LocalizedStringKey = "My level"
    var showTitle: Bool = true

    var body: some View {
        let levels = LanguageLevels.levels(for: languageStore.learningLanguage)
        let current = languageStore.learningLevel

        VStack(alignment: .leading, spacing: 14) {
            if showTitle {
                Text(title)
                    .font(themeStore.bold(18))
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
            }

            FlowLayout(spacing: 10) {
                ForEach(levels) { level in
                    SelectionChip(
                        title: LanguageLevels.localizedLabel(forCode: level.code),
                        color: themeStore.mainAccentColor,
                        isSelected: level.code == current
                    ) {
                        languageStore.learningLevel = level.code
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Unified selection chip (tag style) + wrapping layout

/// A capsule selection chip matching the dictionary tag style. Used everywhere
/// a choice is made (language, level, interests, tags) for a consistent look.
struct SelectionChip: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeStore: ThemeStore

    let title: LocalizedStringKey
    var leading: String? = nil          // optional emoji / flag
    var color: Color
    let isSelected: Bool
    var isDisabled: Bool = false
    var verticalPadding: CGFloat = 10
    var horizontalPadding: CGFloat = 20
    var titleFontSize: CGFloat = 15
    let action: () -> Void

    var body: some View {
        Button {
            guard !isDisabled else { return }
            Haptics.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { action() }
        } label: {
            HStack(spacing: 6) {
                if let leading {
                    Text(leading)
                        .font(.system(size: titleFontSize + 3))
                }
                Text(title)
                    .font(themeStore.medium(titleFontSize))
                    .foregroundStyle(textColor)
            }
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        themeStore.isGlass
                            ? Color.clear
                            : (themeStore.isMonochrome && isSelected
                                ? themeStore.mainText.opacity(0.85)
                                : color.opacity(isSelected ? 0.95 : 0.32))
                    )
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 14))
            .scaleEffect(isSelected ? 1.06 : 1.0)
            .opacity(isDisabled ? 0.4 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var textColor: Color {
        if themeStore.isMonochrome && isSelected { return .white }
        return colorScheme == .dark
            ? .white.opacity(isSelected ? 1.0 : 0.9)
            : darkerShade(of: color, by: 0.45).opacity(isSelected ? 1.0 : 0.9)
    }
}

#Preview {
    LanguageCubePicker(
        selectedLanguage: .constant("Español"),
        title: "I speak",
        languages: LanguageCatalog.availableLanguages
    )
    .environmentObject(ThemeStore())
}
