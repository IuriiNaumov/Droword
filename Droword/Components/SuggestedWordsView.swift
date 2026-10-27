import SwiftUI

struct SuggestedWordsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var suggested: SuggestedWordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @EnvironmentObject private var languageStore: LanguageStore

    @State private var addingWordID: UUID?

    var body: some View {
        if suggested.isLoading || !suggested.suggestedWords.isEmpty || suggested.lastError != nil {
            VStack(alignment: .leading, spacing: 16) {
                Text("Suggestions")
                    .font(themeStore.display(24))
                    .foregroundStyle(themeStore.mainText)
                    .padding(.leading, 16)
                    .padding(.top, 8)

                if let lastError = suggested.lastError {
                    StatusBannerView(
                        icon: "exclamationmark.triangle",
                        iconColor: themeStore.accentRed,
                        title: "Couldn't load suggestions",
                        subtitle: LocalizedStringKey(lastError),
                        useCard: true
                    )
                    .padding(.horizontal, 16)
                }

                if suggested.isLoading {
                    SuggestedWordsSkeletonView()
                        .transition(.opacity.combined(with: .scale))
                } else {
                    VStack(spacing: 16) {
                        ForEach(suggested.suggestedWords) { word in
                            SelectableWordCard(
                                word: word.word.displayCapitalized,
                                translation: word.translation.displayCapitalized,
                                type: word.type,
                                transcription: word.transcription,
                                example: word.example,
                                explanation: word.explanation,
                                breakdown: word.breakdown,
                                collocations: word.collocations,
                                synonyms: word.synonyms,
                                antonyms: word.antonyms,
                                forms: word.forms,
                                isAdding: addingWordID == word.id,
                                onAdd: {
                                    guard addingWordID == nil else { return }
                                    Haptics.softTap()
                                    addingWordID = word.id
                                    Task {
                                        await suggested.accept(word, store: store, languageStore: languageStore)
                                        badgeStore.recordSuggestedWordAccepted()
                                        addingWordID = nil
                                    }
                                },
                                onSkip: {
                                    suggested.skip(word)
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding(.bottom, 8)
            .animation(.easeInOut(duration: 0.3), value: suggested.isLoading)
            .transition(.opacity.combined(with: .slide))
        }
    }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    init(light: String, dark: String) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }

    func toHexRGB() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0
            guard ui.getHue(&h, saturation: &s, brightness: &br, alpha: &a) else { return nil }
            let color = UIColor(hue: h, saturation: s, brightness: br, alpha: 1)
            guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

#Preview {
    let mockStore = WordsStore()
    let suggested: SuggestedWordsStore = {
        let s = SuggestedWordsStore()
        s.suggestedWords = [
            SuggestedWord(
                word: "cabeza",
                translation: "голова",
                type: "noun",
                example: "Me duele la cabeza después de estudiar mucho."
            ),
            SuggestedWord(
                word: "corazón",
                translation: "сердце",
                type: "noun",
                example: "El corazón es un órgano muy importante para el cuerpo."
            )
        ]
        return s
    }()

    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            SuggestedWordsView()
                .environmentObject(mockStore)
                .environmentObject(suggested)
                .environmentObject(LanguageStore())
                .environmentObject(ThemeStore())
                .environmentObject(BadgeStore())
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
    }
    .background(Color("AppBackground"))
}
