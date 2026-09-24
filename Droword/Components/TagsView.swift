import SwiftUI

struct TagsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @Binding var selectedTag: String?
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

    var allTags: [(name: String, color: Color, isCustom: Bool)] {
        let custom: [(name: String, color: Color, isCustom: Bool)] = TagStore.shared.tags.map {
            ($0.name, themeStore.resolvedTagColor($0.colorHex), true)
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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 10 : 14) {
                ForEach(visibleTags, id: \.name) { tag in
                    tagChip(tag)
                        .id(tag.name)
                }

                if showManagementControls {
                    managementControls
                }
            }
            .padding(.horizontal, compact ? 10 : contentInset)
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
            .padding(.vertical, compact ? 8 : 10)
            .padding(.horizontal, compact ? 24 : 28)
            .background(
                Capsule(style: .continuous)
                    .fill(tagFill(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed))
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
            .opacity(dimmed ? 0.45 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDeleteMode && !tag.isCustom)
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
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(themeStore.secondaryText)
                    .frame(width: 34, height: 34)
                    .background(
                        Capsule().fill(themeStore.isGlass ? Color.clear : themeStore.secondaryText.opacity(0.12))
                    )
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
            }
            .opacity(isDeleteMode ? 0 : 1)
        }

        if hasCustomTags {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isDeleteMode.toggle() }
                Haptics.menuTap()
            }) {
                Image(systemName: isDeleteMode ? "checkmark" : "pencil")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isDeleteMode && !themeStore.isGlass ? .white : themeStore.secondaryText)
                    .frame(width: 34, height: 34)
                    .background(
                        Capsule().fill(
                            themeStore.isGlass
                                ? (isDeleteMode ? themeStore.mainAccentColor.opacity(0.28) : Color.clear)
                                : (isDeleteMode ? themeStore.mainAccentColor : themeStore.secondaryText.opacity(0.12))
                        )
                    )
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
            }
            .buttonStyle(.plain)
        }

        Button(action: {
            Haptics.menuTap()
            onAddTag?()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(themeStore.secondaryText)
                .frame(width: 34, height: 34)
                .background(
                    Capsule().fill(themeStore.isGlass ? Color.clear : themeStore.secondaryText.opacity(0.12))
                )
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
        }
        .buttonStyle(.plain)
        .opacity(isDeleteMode ? 0 : 1)
    }

    private func tagFill(isSelected: Bool, baseColor: Color, dimmed: Bool) -> Color {
        if themeStore.isGlass {
            if dimmed { return Color.clear }
            return isSelected ? baseColor.opacity(0.32) : Color.clear
        }
        if dimmed { return baseColor.opacity(0.12) }
        if isSelected {
            return themeStore.isMonochrome ? themeStore.mainText.opacity(0.85) : baseColor
        }
        return baseColor.opacity(0.2)
    }

    private func tagTextColor(isSelected: Bool, baseColor: Color, dimmed: Bool) -> Color {
        if dimmed { return themeStore.secondaryText }
        if themeStore.isGlass {
            return isSelected ? themeStore.mainText : baseColor
        }
        if isSelected { return .white }
        if themeStore.isMonochrome { return themeStore.mainText }
        return baseColor
    }
}

#Preview {
    TagsView(selectedTag: .constant("Street"), hasSuggestedWords: true)
        .environmentObject(ThemeStore())
        .environmentObject(WordsStore())
        .padding()
}
