import SwiftUI

struct WordPacksSectionView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var store: WordsStore

    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    @State private var selectedPack: WordPack?
    @State private var showPremiumWall = false

    var body: some View {
        let packs = WordPacksData.allPacks
        let learning = languageStore.learningLanguage
        let native = languageStore.nativeLanguage

        // Only show packs that have data for current language pair
        let availablePacks = packs.filter {
            WordPacksData.words(packID: $0.id, learning: learning, native: native) != nil
        }

        if !availablePacks.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
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
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(availablePacks) { pack in
                            packCard(pack, learning: learning, native: native)
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
            }
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

    // MARK: - Pack Card

    private func packCard(_ pack: WordPack, learning: String, native: String) -> some View {
        let color = WordPacksData.packColor(for: pack, themeStore: themeStore)
        let isCompleted = WordPackTracker.isCompleted(packID: pack.id, learning: learning, native: native)

        return VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: pack.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(pack.titleKey)
                .font(themeStore.bold(15))
                .foregroundColor(themeStore.mainText)
                .lineLimit(1)

            HStack(spacing: 4) {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(themeStore.accentGreen)

                    Text("Done")
                        .font(themeStore.medium(12))
                        .foregroundColor(themeStore.accentGreen)
                } else {
                    Text("\(pack.wordCount) words")
                        .font(themeStore.regular(12))
                        .foregroundColor(themeStore.secondaryText)
                }
            }
        }
        .padding(16)
        .frame(width: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 20))
    }
}

#Preview {
    WordPacksSectionView()
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
        .environmentObject(WordsStore())
        .padding()
}
