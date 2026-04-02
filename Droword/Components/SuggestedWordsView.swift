import SwiftUI

struct SuggestedWordsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var suggested: SuggestedWordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @EnvironmentObject private var languageStore: LanguageStore

    private var accent: Color { themeStore.accentBlue }

    var body: some View {
        if suggested.isLoading || !suggested.suggestedWords.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                if suggested.topic != nil {
                    Text("Suggestions")
                        .font(themeStore.bold(24))
                        .foregroundColor(themeStore.mainText)
                        .padding(.top, 8)
                }

                if suggested.isLoading {
                    SuggestedWordsSkeletonView()
                        .transition(.opacity.combined(with: .scale))
                } else {
                    VStack(spacing: 16) {
                        ForEach(suggested.suggestedWords) { word in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(word.word.capitalized)
                                    .font(themeStore.bold(24))
                                    .foregroundColor(themeStore.mainText)

                                Text(word.translation)
                                    .font(themeStore.regular(16))
                                    .foregroundColor(themeStore.secondaryText)

                                if let example = word.example {
                                    Text(highlightedExample(example, word: word.word))
                                        .font(themeStore.regular(16))
                                        .foregroundColor(themeStore.mainText)
                                }

                                HStack {
                                    Button {
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
                                        .foregroundColor(.white)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(accent)
                                        .clipShape(Capsule())
                                        
                                    }

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
                                        .foregroundColor(accent)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(accent.opacity(0.15))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

    private func highlightedExample(_ text: String, word: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: word, options: .caseInsensitive) {
            attributed[range].foregroundColor = UIColor(themeStore.accentGold)
            attributed[range].font = UIFont(name: themeStore.fontBold, size: 16) ?? .boldSystemFont(ofSize: 16)
        }
        return attributed
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
}

#Preview {
    let mockStore = WordsStore()
    let suggested: SuggestedWordsStore = {
        let s = SuggestedWordsStore()
        s.topic = "Everyday life"
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
