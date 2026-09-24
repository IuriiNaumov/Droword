import SwiftUI

struct SuggestedWordsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var suggested: SuggestedWordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @EnvironmentObject private var languageStore: LanguageStore

    private var accent: Color { themeStore.accentBlue }

    @State private var cachedExamples: [String: AttributedString] = [:]

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
                        icon: "exclamationmark.triangle.fill",
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
                            VStack(alignment: .leading, spacing: 10) {
                                Text(word.word.displayCapitalized)
                                    .font(themeStore.medium(24))
                                    .foregroundStyle(themeStore.mainText)

                                Text(word.translation.displayCapitalized)
                                    .font(themeStore.regular(16))
                                    .foregroundStyle(themeStore.secondaryText)

                                if let _ = word.example,
                                   let attributed = cachedExamples[word.id.uuidString] {
                                    Text(attributed)
                                        .font(themeStore.regular(16))
                                        .foregroundStyle(themeStore.mainText)
                                }

                                HStack {
                                    Button {
                                        Haptics.softTap()
                                        withAnimation(.spring()) {
                                            suggested.accept(word, store: store, languageStore: languageStore)
                                            badgeStore.recordSuggestedWordAccepted()
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add")
                                        }
                                        .font(themeStore.medium(13))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 7)
                                        .padding(.horizontal, 14)
                                        .background(Capsule().fill(accent))
                                    }
                                    .buttonStyle(PressableButtonStyle())

                                    Spacer()

                                    Button {
                                        withAnimation(.easeInOut) {
                                            suggested.skip(word)
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle")
                                            Text("Already know")
                                        }
                                        .font(themeStore.regular(13))
                                        .foregroundStyle(accent)
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                }
                                .padding(.top, 10)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                                    .fill(accent.opacity(0.15))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding(.bottom, 8)
            .animation(.easeInOut(duration: 0.3), value: suggested.isLoading)
            .transition(.opacity.combined(with: .slide))
            .onAppear { rebuildExampleCache() }
            .onChange(of: suggested.suggestedWords.count) { rebuildExampleCache() }
        }
    }

    private func rebuildExampleCache() {
        var cache: [String: AttributedString] = [:]
        for word in suggested.suggestedWords {
            guard let example = word.example else { continue }
            var attributed = AttributedString(example)
            if let range = attributed.range(of: word.word, options: .caseInsensitive) {
                attributed[range].foregroundColor = UIColor(themeStore.accentGold)
                attributed[range].font = themeStore.uiFont(size: 16, weight: .bold)
            }
            cache[word.id.uuidString] = attributed
        }
        cachedExamples = cache
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
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
    }
    .background(Color("AppBackground"))
}
