import SwiftUI

struct WordPacksSectionView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var store: WordsStore

    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.showWordPacks) private var showWordPacks: Bool = true
    @AppStorage(AppStorageKeys.hasSeenWordPacksHint) private var hasSeenHint: Bool = false

    @State private var selectedPack: WordPack?
    @State private var showPremiumWall = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let packs = WordPacksData.allPacks
        let learning = languageStore.learningLanguage
        let native = languageStore.nativeLanguage

        // Filter out packs with no data AND completed packs
        let availablePacks = packs.filter {
            WordPacksData.words(packID: $0.id, learning: learning, native: native) != nil
            && !WordPackTracker.isCompleted(packID: $0.id, learning: learning, native: native)
        }

        if !availablePacks.isEmpty && showWordPacks {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Text("Word Packs")
                        .font(themeStore.bold(24))
                        .foregroundColor(themeStore.mainText)

                    if !isPremium {
                        Text("PRO")
                            .font(themeStore.bold(9))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(themeStore.accentBlue))
                    }

                    Spacer()
                }

                // Mini pack cards — scrollable row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availablePacks) { pack in
                            miniPackCard(pack, learning: learning, native: native)
                                .onTapGesture {
                                    Haptics.lightImpact()
                                    if isPremium {
                                        selectedPack = pack
                                    } else {
                                        showPremiumWall = true
                                    }
                                }
                        }
                    }
                }

                // One-time hint
                if !hasSeenHint {
                    Text("You can hide this section in Dictionary settings.")
                        .font(themeStore.regular(13))
                        .foregroundColor(themeStore.secondaryText)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    hasSeenHint = true
                                }
                            }
                        }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 24))
            .padding(.horizontal, 20)
            .fullScreenCover(item: $selectedPack) { pack in
                WordPackDetailView(pack: pack)
                    .environmentObject(themeStore)
                    .environmentObject(languageStore)
                    .environmentObject(store)
            }
            .fullScreenCover(isPresented: $showPremiumWall) {
                PremiumView(asWall: true)
                    .environmentObject(themeStore)
                    .tint(themeStore.mainAccentColor)
            }
        }
    }

    // MARK: - Mini Pack Card (StatCardView style)

    private func miniPackCard(_ pack: WordPack, learning: String, native: String) -> some View {
        let color = WordPacksData.packColor(for: pack, themeStore: themeStore)

        return VStack(spacing: 6) {
            Image(systemName: pack.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            Text(pack.titleKey)
                .font(themeStore.medium(13))
                .foregroundColor(themeStore.isMonochrome ? .white.opacity(0.75) : themeStore.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.isGlass
                      ? Color.clear
                      : (themeStore.isMonochrome
                         ? themeStore.mainText.opacity(colorScheme == .dark ? 0.7 : 0.75)
                         : themeStore.appBg))
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
    }
}

#Preview {
    WordPacksSectionView()
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
        .environmentObject(WordsStore())
        .padding()
}
