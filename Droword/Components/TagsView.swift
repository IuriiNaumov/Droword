import SwiftUI

struct TagsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Binding var selectedTag: String?
    @ObservedObject private var tagStore = TagStore.shared
    var compact: Bool = false
    var hasSuggestedWords: Bool = false
    var showManagementControls: Bool = true
    var onAddTag: (() -> Void)? = nil
    var sortOption: Binding<DictionarySortOption>? = nil
    @State private var isDeleteMode: Bool = false

    private let builtInNames: Set<String> = ["Suggested", "Travel", "Movie", "Street", "Social media"]

    var allTags: [(name: String, color: Color, isCustom: Bool)] {
        let custom: [(name: String, color: Color, isCustom: Bool)] = TagStore.shared.tags.map {
            ($0.name, themeStore.resolvedTagColor($0.colorHex), true)
        }
        let builtIn: [(name: String, color: Color, isCustom: Bool)] = [
            ("Suggested", themeStore.accentBlue, false),
            ("Travel", themeStore.accentBlue, false),
            ("Movie", themeStore.accentPink, false),
            ("Street", themeStore.accentPurple, false),
            ("Social media", themeStore.accentGold, false),
        ]
        return custom + builtIn
    }

    var visibleTags: [(name: String, color: Color, isCustom: Bool)] {
        allTags.filter { tag in
            tag.name == "Suggested" ? hasSuggestedWords : true
        }
    }

    private var hasCustomTags: Bool {
        !tagStore.tags.isEmpty
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 10 : 14) {
                ForEach(visibleTags, id: \.name) { tag in
                    let isSelected = selectedTag == tag.name
                    let baseColor = tag.color
                    let dimmed = isDeleteMode && !tag.isCustom

                    Button {
                        if isDeleteMode {
                            if tag.isCustom {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    TagStore.shared.removeTag(named: tag.name)
                                    if selectedTag == tag.name { selectedTag = nil }
                                }
                                Haptics.warning()
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                selectedTag = selectedTag == tag.name ? nil : tag.name
                            }
                            Haptics.tick()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isDeleteMode && tag.isCustom {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.accentRed)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            Text(LocalizedStringKey(tag.name))
                                .font(themeStore.medium(compact ? 13 : 15))
                                .foregroundStyle(tagTextColor(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed))

                            if isDeleteMode && !tag.isCustom {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(tagTextColor(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed).opacity(0.5))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, compact ? 8 : 10)
                        .padding(.horizontal, compact ? 24 : 28)
                        .background(
                            Capsule(style: .continuous)
                                .fill(tagFill(isSelected: isSelected, baseColor: baseColor, dimmed: dimmed))
                        )
                        .scaleEffect(isSelected && !isDeleteMode ? 1.04 : 1.0)
                        .opacity(dimmed ? 0.45 : 1.0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isDeleteMode)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeleteMode && !tag.isCustom)
                }

                if showManagementControls {
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
                                .background(Capsule().fill(themeStore.secondaryText.opacity(0.12)))
                        }
                        .opacity(isDeleteMode ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isDeleteMode)
                    }

                    if hasCustomTags {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isDeleteMode.toggle() }
                            Haptics.menuTap()
                        }) {
                            Image(systemName: isDeleteMode ? "checkmark" : "pencil")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(isDeleteMode ? .white : themeStore.secondaryText)
                                .frame(width: 34, height: 34)
                                .background(
                                    Capsule().fill(isDeleteMode ? themeStore.mainAccentColor : themeStore.secondaryText.opacity(0.12))
                                )
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
                            .background(Capsule().fill(themeStore.secondaryText.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .opacity(isDeleteMode ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isDeleteMode)
                }
            }
            .padding(.horizontal, compact ? 10 : 0)
            .padding(.vertical, compact ? 14 : 8)
        }
        .onChange(of: tagStore.tags.count) { _, newCount in
            if newCount == 0 && isDeleteMode {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDeleteMode = false
                }
            }
        }
    }

    private func tagFill(isSelected: Bool, baseColor: Color, dimmed: Bool) -> Color {
        if themeStore.isGlass { return Color.clear }
        if dimmed { return baseColor.opacity(0.12) }
        if isSelected {
            return themeStore.isMonochrome ? themeStore.mainText.opacity(0.85) : baseColor
        }
        return baseColor.opacity(0.2)
    }

    private func tagTextColor(isSelected: Bool, baseColor: Color, dimmed: Bool) -> Color {
        if dimmed { return themeStore.secondaryText }
        if isSelected { return .white }
        if themeStore.isMonochrome { return themeStore.mainText }
        return baseColor
    }
}

#Preview {
    TagsView(selectedTag: .constant("Street"), hasSuggestedWords: true)
        .environmentObject(ThemeStore())
        .padding()
}
