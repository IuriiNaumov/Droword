import SwiftUI

struct TagsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTag: String?
    var selectedReaction: Binding<String?>? = nil
    @ObservedObject private var tagStore = TagStore.shared
    var compact: Bool = false
    var hasSuggestedWords: Bool = false
    var showManagementControls: Bool = true
    var onAddTag: (() -> Void)? = nil
    var sortOption: Binding<DictionarySortOption>? = nil
    var contentInset: CGFloat = 0
    @State private var isDeleteMode: Bool = false
    @State private var scrollPosition: String?

    private let builtInNames: Set<String> = BuiltInTag.allStoredNames
    private var duo: Bool { themeStore.isDuolingo && !themeStore.isGlass }

    var allTags: [(name: String, color: Color, isCustom: Bool)] {
        let custom: [(name: String, color: Color, isCustom: Bool)] = TagStore.shared.tags.map {
            ($0.name, themeStore.colorForTag($0.name), true)
        }
        let builtIn: [(name: String, color: Color, isCustom: Bool)] = [
            (BuiltInTag.suggested, themeStore.accentBlue, false),
            (BuiltInTag.travel, themeStore.accentBlue, false),
            (BuiltInTag.movie, themeStore.accentPink, false),
            (BuiltInTag.street, themeStore.accentPurple, false),
            (BuiltInTag.socialMedia, themeStore.accentGold, false),
        ]
        return custom + builtIn
    }

    var visibleTags: [(name: String, color: Color, isCustom: Bool)] {
        allTags.filter { tag in
            tag.name == BuiltInTag.suggested ? hasSuggestedWords : true
        }
    }

    private var hasCustomTags: Bool {
        !tagStore.tags.isEmpty
    }

    private var usedReactions: [String] {
        guard selectedReaction != nil else { return [] }
        var seen = Set<String>()
        var ordered: [String] = []
        for emoji in WordCardView.availableReactions {
            if store.words.contains(where: { $0.reaction == emoji }) {
                ordered.append(emoji)
                seen.insert(emoji)
            }
        }
        for word in store.words {
            guard let reaction = word.reaction, !reaction.isEmpty, !seen.contains(reaction) else { continue }
            ordered.append(reaction)
            seen.insert(reaction)
        }
        return ordered
    }

    private var rowSpacing: CGFloat { compact ? 10 : 14 }
    private var rowInset: CGFloat { compact ? 10 : contentInset }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: rowSpacing) {
                tagChips
                reactionChips
                if showManagementControls {
                    if isDeleteMode {
                        doneEditingButton
                    } else {
                        managementControls
                    }
                }
            }
            .padding(.horizontal, rowInset)
            .padding(.vertical, compact ? 14 : 10)
        }
        .scrollPosition(id: $scrollPosition)
        .scrollClipDisabled()
        .onChange(of: tagStore.tags.count) { _, newCount in
            if newCount == 0 && isDeleteMode {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDeleteMode = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exitDictionarySelect)) { _ in
            guard isDeleteMode else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isDeleteMode = false
            }
        }
    }

    private var tagChips: some View {
        HStack(spacing: rowSpacing) {
            ForEach(visibleTags, id: \.name) { tag in
                tagChip(tag)
                    .id(tag.name)
            }
        }
    }

    private var doneEditingButton: some View {
        let textColor: Color = themeStore.isGlass
            ? (colorScheme == .dark ? .white : .black)
            : .white
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isDeleteMode = false
            }
            Haptics.menuTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                Text("Done")
                    .font(themeStore.bold(15))
            }
            .foregroundStyle(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .duo3DChipFilled(themeStore.mainAccentColor, cornerRadius: themeStore.controlRadius)
        }
        .buttonStyle(Duo3DButtonStyle())
    }

    @ViewBuilder
    private func tagChip(_ tag: (name: String, color: Color, isCustom: Bool)) -> some View {
        let isSelected = selectedTag == tag.name
        let baseColor = tag.color
        let dimmed = isDeleteMode && !tag.isCustom

        Button {
            if isDeleteMode {
                if tag.isCustom {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        store.clearTag(tag.name)
                        TagStore.shared.removeTag(named: tag.name)
                        if selectedTag == tag.name { selectedTag = nil }
                    }
                    Haptics.warning()
                }
            } else {
                selectedReaction?.wrappedValue = nil
                selectedTag = selectedTag == tag.name ? nil : tag.name
                Haptics.tick()
            }
        } label: {
            HStack(spacing: 6) {
                if isDeleteMode && tag.isCustom {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentRed)
                        .transition(.opacity)
                }

                Text(BuiltInTag.displayName(tag.name))
                    .font(themeStore.medium(compact ? 13 : 15))
                    .foregroundStyle(tagTextColor(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed))

                if isDeleteMode && !tag.isCustom {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(tagTextColor(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed).opacity(0.5))
                        .transition(.opacity)
                }
            }
            .frame(height: DesignChip.circleSize(compact: compact))
            .padding(.horizontal, compact ? 24 : 28)
            .background { tagBackground(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed) }
            .overlay { tagBorder(isSelected: isSelected) }
            .padding(.bottom, duo ? 3 : 0)
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
            .opacity(dimmed ? 0.45 : 1.0)
        }
        .buttonStyle(Duo3DButtonStyle())
        .disabled(isDeleteMode && !tag.isCustom)
    }

    @ViewBuilder
    private var reactionChips: some View {
        if let selectedReaction, !usedReactions.isEmpty {
            HStack(spacing: rowSpacing) {
                ForEach(usedReactions, id: \.self) { emoji in
                    reactionChip(emoji, selectedReaction: selectedReaction)
                        .id("reaction-\(emoji)")
                }
            }
        }
    }

    private func reactionChip(_ emoji: String, selectedReaction: Binding<String?>) -> some View {
        let isSelected = selectedReaction.wrappedValue == emoji
        let baseColor = themeStore.accentBlue
        let size = DesignChip.circleSize(compact: compact)

        return Button {
            guard !isDeleteMode else { return }
            selectedTag = nil
            selectedReaction.wrappedValue = isSelected ? nil : emoji
            Haptics.tick()
        } label: {
            Text(emoji)
                .font(.system(size: DesignChip.emojiSize(compact: compact)))
                .frame(width: size, height: size)
                .background { reactionBackground(isSelected: isSelected, baseColor: baseColor) }
                .overlay { reactionBorder(isSelected: isSelected) }
                .padding(.bottom, duo ? 3 : 0)
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .circle))
                .opacity(isDeleteMode ? 0.45 : 1.0)
        }
        .buttonStyle(Duo3DButtonStyle())
        .disabled(isDeleteMode)
        .accessibilityLabel(Text("Reaction \(emoji)"))
    }

    @ViewBuilder
    private func reactionBackground(isSelected: Bool, baseColor: Color) -> some View {
        if duo {
            let face: Color = {
                if isSelected {
                    return baseColor
                }
                return themeStore.controlFace
            }()
            let lip = isSelected
                ? darkerShade(of: face, by: 0.16)
                : Color(hex: "#AFAFAF").opacity(0.45)
            ZStack {
                Circle()
                    .fill(lip)
                    .offset(y: 3)
                Circle()
                    .fill(face)
            }
        } else {
            Circle()
                .fill(tagFill(isSelected: isSelected, baseColor: baseColor, dimmed: false))
        }
    }

    @ViewBuilder
    private func reactionBorder(isSelected: Bool) -> some View {
        if duo, !isSelected {
            Circle()
                .strokeBorder(themeStore.dividerColor, lineWidth: 2)
        }
    }

    @ViewBuilder
    private func tagBackground(isSelected: Bool, baseColor: Color, dimmed: Bool) -> some View {
        let radius = themeStore.chipRadius
        if duo {
            let face: Color = {
                if dimmed { return baseColor.opacity(0.12) }
                if isSelected {
                    return baseColor
                }
                return themeStore.controlFace
            }()
            let lip = isSelected && !dimmed
                ? darkerShade(of: face, by: 0.16)
                : Color(hex: "#AFAFAF").opacity(0.45)
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(lip)
                    .offset(y: 3)
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(face)
            }
        } else {
            Capsule(style: .continuous)
                .fill(tagFill(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed))
        }
    }

    @ViewBuilder
    private func tagBorder(isSelected: Bool) -> some View {
        if duo, !isSelected {
            RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                .strokeBorder(themeStore.dividerColor, lineWidth: 2)
        }
    }

    @ViewBuilder
    private var managementControls: some View {
        if let sortBinding = sortOption {
            Menu {
                ForEach(DictionarySortOption.allCases, id: \.self) { option in
                    Button {
                        sortBinding.wrappedValue = option
                        Haptics.tick()
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if sortBinding.wrappedValue == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                managementIcon("arrow.up.arrow.down", filled: false)
            }
        }

        if hasCustomTags {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isDeleteMode = true }
                Haptics.menuTap()
            }) {
                managementIcon("pencil", filled: false)
            }
            .buttonStyle(Duo3DButtonStyle())
        }

        Button(action: {
            Haptics.menuTap()
            onAddTag?()
        }) {
            managementIcon("plus", filled: false)
        }
        .buttonStyle(Duo3DButtonStyle())
    }

    private func managementIcon(_ name: String, filled: Bool, fillColor: Color? = nil) -> some View {
        let face = filled ? (fillColor ?? themeStore.mainAccentColor) : (duo ? themeStore.controlFace : themeStore.secondaryText.opacity(0.12))
        let size = DesignChip.circleSize(compact: compact)
        return Image(systemName: name)
            .font(.system(size: compact ? 13 : 14, weight: .bold))
            .foregroundStyle(filled && !themeStore.isGlass ? Color.white : themeStore.secondaryText)
            .frame(width: size, height: size)
            .background {
                if duo {
                    ZStack {
                        Circle()
                            .fill(filled ? darkerShade(of: face, by: 0.16) : Color(hex: "#AFAFAF").opacity(0.45))
                            .offset(y: 3)
                        Circle()
                            .fill(face)
                    }
                } else {
                    Circle().fill(themeStore.isGlass && !filled ? Color.clear : face)
                }
            }
            .overlay {
                if duo, !filled {
                    Circle()
                        .strokeBorder(themeStore.dividerColor, lineWidth: 2)
                }
            }
            .padding(.bottom, duo ? 3 : 0)
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .circle))
    }

    private func tagFill(isSelected: Bool, baseColor: Color, dimmed: Bool) -> Color {
        if themeStore.isGlass {
            if dimmed { return Color.clear }
            return isSelected ? baseColor.opacity(0.32) : Color.clear
        }
        if dimmed { return baseColor.opacity(0.12) }
        if isSelected {
            return baseColor
        }
        return baseColor.opacity(0.2)
    }

    private func tagTextColor(isSelected: Bool, baseColor: Color, dimmed: Bool) -> Color {
        if dimmed { return themeStore.secondaryText }
        if themeStore.isGlass {
            return isSelected ? themeStore.mainText : baseColor
        }
        if duo {
            if isSelected { return .white }
            return themeStore.mainText
        }
        if isSelected { return .white }
        return baseColor
    }
}

#Preview {
    TagsView(selectedTag: .constant("Street"), hasSuggestedWords: true)
        .environmentObject(ThemeStore())
        .environmentObject(WordsStore())
        .padding()
}
