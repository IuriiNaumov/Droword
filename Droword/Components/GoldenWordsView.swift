import SwiftUI

struct GoldenWordsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var golden: GoldenWordsStore

    private let gold = Color.accentGold
    private var darkGold: Color { darkerShade(of: Color.accentGold, by: 0.15) }
    private var midTextGold: Color { darkerShade(of: Color.accentGold, by: 0.35) }
    private var titleGold: Color { darkerShade(of: Color.accentGold, by: 0.5) }

    var body: some View {
        if golden.isLoading || !golden.goldenWords.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                if let topic = golden.topic {
                    Text("Suggestions")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.mainBlack)
                        .padding(.top, 8)
                }

                if golden.isLoading {
                    GoldenWordsSkeletonView()
                        .transition(.opacity.combined(with: .scale))
                } else {
                    VStack(spacing: 16) {
                        ForEach(golden.goldenWords) { word in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(word.word.capitalized)
                                    .font(.custom("Poppins-Bold", size: 24))
                                    .foregroundColor(.mainBlack)

                                Text(word.translation)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.mainGrey)

                                if let example = word.example {
                                    Text(example)
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.mainBlack)
                                }

                                HStack {
                                    Button {
                                        withAnimation(.spring()) {
                                            golden.accept(word, store: store, languageStore: LanguageStore())
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add (+20 XP)")
                                        }
                                        .font(.custom("Poppins-Medium", size: 13))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(darkGold)
                                        .clipShape(Capsule())
                                        
                                    }

                                    Spacer()

                                    Button {
                                        withAnimation(.easeInOut) {
                                            golden.skip(word)
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle")
                                            Text("Already know")
                                        }
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(midTextGold)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(gold)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(Color.divider, lineWidth: 1)
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding(.bottom, 8)
            .animation(.easeInOut(duration: 0.3), value: golden.isLoading)
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
}

#Preview {
    let mockStore = WordsStore()
    let golden = GoldenWordsStore()
    golden.topic = "Everyday life"
    golden.goldenWords = [
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

    return ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            GoldenWordsView()
                .environmentObject(mockStore)
                .environmentObject(golden)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
    }
    .background(Color.appBackground)
}
