import SwiftUI

struct WordPacksButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore

    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    let availableCount: Int

    var body: some View {
        HStack(spacing: 14) {
                Image(systemName: "rectangle.stack")
                .font(.system(size: 20, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .symbolVariant(.none)
                .foregroundStyle(themeStore.mainText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Word Packs")
                        .font(themeStore.bold(16))
                        .foregroundStyle(themeStore.mainText)

                    if !isPremium {
                        ProPillBadge()
                    }
                }

                Text(availableCount == 1
                     ? String(localized: "1 pack ready")
                     : String(localized: "\(availableCount) packs ready"))
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(themeStore.accentBlue)
                .frame(width: 28, height: 28)
        }
        .padding(DesignSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
    }
}

struct WordPacksDetailView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var store: WordsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasSeenWordPacksHint) private var hasSeenHint: Bool = false

    @State private var selectedPack: WordPack?

    private var learning: String { languageStore.learningLanguage }
    private var native: String { languageStore.nativeLanguage }

    private var availablePacks: [WordPack] {
        WordPacksData.allPacks.filter {
            WordPacksData.words(packID: $0.id, learning: learning, native: native) != nil
            && !WordPackTracker.isCompleted(packID: $0.id, learning: learning, native: native)
        }
    }

    private var completedPacks: [WordPack] {
        WordPacksData.allPacks.filter {
            WordPacksData.words(packID: $0.id, learning: learning, native: native) != nil
            && WordPackTracker.isCompleted(packID: $0.id, learning: learning, native: native)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text("Word Packs")
                        .sheetTitle()

                    if !hasSeenHint {
                        Text("Pick a pack, add the words, then practice.")
                            .font(themeStore.regular(14))
                            .foregroundStyle(themeStore.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                    withAnimation { hasSeenHint = true }
                                }
                            }
                    }

                    if availablePacks.isEmpty && completedPacks.isEmpty {
                        EmptyListView(
                            icon: "rectangle.stack",
                            title: String(localized: "No packs yet"),
                            subtitle: String(localized: "Packs for this language pair will show up here.")
                        )
                        .frame(minHeight: 220)
                    } else {
                        if !availablePacks.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(availablePacks) { pack in
                                    packRow(pack, completed: false)
                                }
                            }
                        }

                        if !completedPacks.isEmpty {
                            sectionHeader(String(localized: "Completed"))
                            VStack(spacing: 12) {
                                ForEach(completedPacks) { pack in
                                    packRow(pack, completed: true)
                                }
                            }
                        }
                    }

                    HomeVisibilityHint(message: "You can hide Word Packs from Home whenever you want.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
            .fullScreenCover(item: $selectedPack) { pack in
                WordPackDetailView(pack: pack)
                    .environmentObject(themeStore)
                    .environmentObject(languageStore)
                    .environmentObject(store)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(themeStore.bold(14))
            .foregroundStyle(themeStore.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func packRow(_ pack: WordPack, completed: Bool) -> some View {
        Button {
            Haptics.menuTap()
            if completed { return }
            selectedPack = pack
        } label: {
            HStack(spacing: 14) {
                Image(systemName: completed ? "checkmark" : pack.icon)
                    .font(.system(size: 20, weight: completed ? .bold : .regular))
                    .symbolRenderingMode(.monochrome)
                    .symbolVariant(.none)
                    .foregroundStyle(completed ? themeStore.accentBlue : themeStore.mainText)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.titleKey)
                        .font(themeStore.medium(16))
                        .foregroundStyle(completed ? themeStore.secondaryText : themeStore.mainText)

                    Text(pack.descriptionKey)
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                        .lineLimit(2)

                    Text(String(localized: "\(pack.wordCount) words"))
                        .font(themeStore.regular(12))
                        .foregroundStyle(themeStore.secondaryText.opacity(0.7))
                }

                Spacer()

                if !completed {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(themeStore.secondaryText.opacity(0.45))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.card))
            .opacity(completed ? 0.75 : 1)
        }
        .buttonStyle(.plain)
        .disabled(completed)
    }
}

enum WordPacksHome {
    static func availableCount(learning: String, native: String) -> Int {
        WordPacksData.allPacks.filter {
            WordPacksData.words(packID: $0.id, learning: learning, native: native) != nil
            && !WordPackTracker.isCompleted(packID: $0.id, learning: learning, native: native)
        }.count
    }
}

#Preview("Button") {
    WordPacksButton(availableCount: 3)
        .padding()
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
}

#Preview("Detail") {
    NavigationStack {
        WordPacksDetailView()
    }
    .environmentObject(ThemeStore())
    .environmentObject(LanguageStore())
    .environmentObject(WordsStore())
}
