import SwiftUI

struct LanguageCubePicker: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Binding var selectedLanguage: String
    var title: LocalizedStringKey
    var languages: [LanguageOption]
    var blockedLanguage: String? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)
                .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(languages) { lang in
                    let isBlocked = lang.name == blockedLanguage
                    LanguageCube(
                        language: lang,
                        isSelected: selectedLanguage == lang.name,
                        isBlocked: isBlocked
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedLanguage = lang.name
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }
}

struct LanguageLevelPicker: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore

    var title: LocalizedStringKey = "My level"
    var showTitle: Bool = true
    var color: Color? = nil

    var body: some View {
        let levels = LanguageLevels.levels(for: languageStore.learningLanguage)
        let current = languageStore.learningLevel

        VStack(alignment: .leading, spacing: 14) {
            if showTitle {
                Text(title)
                    .font(themeStore.bold(18))
                    .foregroundStyle(themeStore.mainText)
                    .padding(.horizontal, 20)
            }

            FlowLayout(spacing: 10) {
                ForEach(levels) { level in
                    SelectionChip(
                        title: LanguageLevels.localizedLabel(forCode: level.code),
                        color: color ?? themeStore.mainAccentColor,
                        isSelected: level.code == current,
                        tintSelection: true
                    ) {
                        languageStore.learningLevel = level.code
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
}

struct SelectionChip: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let title: LocalizedStringKey
    var leading: String? = nil
    var color: Color
    let isSelected: Bool
    var isDisabled: Bool = false
    var tintSelection: Bool = false
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
                    .foregroundStyle(chipTitleColor)
            }
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background { chipBackground }
            .overlay { chipBorder }
            .padding(.bottom, duo ? 3 : 0)
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isSelected, cornerRadius: duo ? 12 : 20))
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .opacity(isDisabled ? 0.4 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelected)
        }
        .buttonStyle(Duo3DButtonStyle())
        .disabled(isDisabled)
    }

    private var duo: Bool { themeStore.isDuolingo && !themeStore.isGlass }

    private var chipTitleColor: Color {
        if duo {
            if isSelected { return .white }
            return themeStore.mainText
        }
        if isSelected, !tintSelection {
            return themeStore.isGlass ? themeStore.mainText : Color.white
        }
        return themeStore.mainText
    }

    @ViewBuilder
    private var chipBackground: some View {
        if duo {
            let face: Color = isSelected ? color : themeStore.controlFace
            let lip = isSelected ? darkerShade(of: color, by: 0.16) : Color(hex: "#AFAFAF").opacity(0.45)
            ZStack {
                RoundedRectangle(cornerRadius: duo ? themeStore.chipRadius : 12, style: .continuous)
                    .fill(lip)
                    .offset(y: 3)
                RoundedRectangle(cornerRadius: duo ? themeStore.chipRadius : 12, style: .continuous)
                    .fill(face)
            }
        } else {
            Capsule(style: .continuous)
                .fill(chipFill)
        }
    }

    @ViewBuilder
    private var chipBorder: some View {
        if duo, !isSelected {
            RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                .strokeBorder(themeStore.dividerColor, lineWidth: 2)
        }
    }

    private var chipFill: Color {
        if isSelected {
            if tintSelection { return color.opacity(0.14) }
            return themeStore.isGlass ? color.opacity(0.28) : color
        }
        return themeStore.isGlass ? Color.clear : themeStore.cardBg
    }
}

struct LanguagePairHero: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let nativeName: String
    let learningName: String
    var onSwap: (() -> Void)? = nil

    private func flag(for name: String) -> String {
        LanguageCatalog.availableLanguages.first { $0.name == name }?.flag ?? "🏳️"
    }

    var body: some View {
        HStack(spacing: 0) {
            pairSide(flag: flag(for: nativeName), name: nativeName, caption: String(localized: "I speak"))

            Button {
                onSwap?()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(themeStore.mainAccentColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(themeStore.mainAccentColor.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            .disabled(onSwap == nil)
            .opacity(onSwap == nil ? 0.45 : 1)
            .accessibilityLabel(Text("Swap languages"))

            pairSide(flag: flag(for: learningName), name: learningName, caption: String(localized: "I'm learning"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))
        .padding(.horizontal, 20)
    }

    private func pairSide(flag: String, name: String, caption: String) -> some View {
        VStack(spacing: 8) {
            LanguageFlagView(language: name.isEmpty ? flag : name, width: 44, height: 30)

            Text(caption)
                .font(themeStore.regular(12))
                .foregroundStyle(themeStore.secondaryText)

            Text(name)
                .font(themeStore.bold(15))
                .foregroundStyle(themeStore.mainText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
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
