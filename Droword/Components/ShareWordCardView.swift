import SwiftUI
import UIKit

struct ShareWordCardView: View {
    let word: StoredWord
    @ObservedObject var themeStore: ThemeStore
    var cardWidth: CGFloat = 340

    private var primaryTextColor: Color { themeStore.mainText }
    private var secondaryTextColor: Color { themeStore.mainText.opacity(0.8) }

    private var shareExamples: [String] {
        var list: [String] = []
        if let example = word.example, !example.isEmpty {
            list.append(example)
        }
        for sentence in word.examples where !sentence.isEmpty {
            if list.contains(sentence) { continue }
            list.append(sentence)
            if list.count >= 3 { break }
        }
        return list
    }

    var body: some View {
        cardContent
            .overlay(alignment: .topTrailing) {
                if let reaction = word.reaction, !reaction.isEmpty {
                    Text(reaction)
                        .font(.system(size: DesignChip.emoji))
                        .frame(width: DesignChip.circle, height: DesignChip.circle)
                        .background(
                            Circle()
                                .fill(themeStore.accentBlueSoft)
                        )
                        .offset(x: -4, y: -18)
                }
            }
            .padding(.top, word.reaction.map { !$0.isEmpty } == true ? 14 : 0)
            .environmentObject(themeStore)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let tag = word.tag, !tag.isEmpty {
                TagBadge(text: tag)
                    .padding(.bottom, 2)
            }

            leadingText(word.word, font: themeStore.medium(24), color: primaryTextColor)
                .tracking(-0.2)

            if let transcription = word.transcription, !transcription.isEmpty {
                leadingText("[\(transcription)]", font: themeStore.regular(14), color: secondaryTextColor)
            }

            if !word.type.isEmpty {
                leadingText(word.type.capitalized, font: themeStore.regular(14), color: secondaryTextColor)
                    .padding(.bottom, 2)
            }

            if let translation = word.translation, !translation.isEmpty {
                leadingText(translation, font: themeStore.regular(16), color: primaryTextColor)
            }

            ForEach(Array(shareExamples.enumerated()), id: \.offset) { _, sentence in
                Text(highlightedSentence(sentence))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let explanation = word.explanation, !explanation.isEmpty {
                leadingText(explanation, font: themeStore.regular(16), color: primaryTextColor)
            }

            if let breakdown = word.breakdown, !breakdown.isEmpty {
                leadingText(breakdown, font: themeStore.regular(16), color: primaryTextColor)
            }

            if !word.collocations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    leadingText("Common phrases", font: themeStore.medium(13), color: themeStore.secondaryText)
                    leadingText(word.collocations.joined(separator: "  ·  "), font: themeStore.regular(15), color: primaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
            }

            if !word.synonyms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    leadingText("Synonyms", font: themeStore.medium(13), color: themeStore.secondaryText)
                    leadingText(word.synonyms.joined(separator: "  ·  "), font: themeStore.regular(15), color: primaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
            }

            if !word.antonyms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    leadingText("Opposites", font: themeStore.medium(13), color: themeStore.secondaryText)
                    leadingText(word.antonyms.joined(separator: "  ·  "), font: themeStore.regular(15), color: primaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
            }

            if let comment = word.comment, !comment.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundStyle(themeStore.secondaryText.opacity(0.7))
                        .padding(.top, 2)
                    leadingText(comment, font: themeStore.regular(16), color: themeStore.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSpacing.md)
        .frame(width: cardWidth, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))
    }

    private func leadingText(_ text: String, font: Font, color: Color) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func highlightedSentence(_ sentence: String) -> AttributedString {
        HighlightedExample.make(
            example: sentence,
            word: word.word,
            forms: word.forms,
            baseColor: UIColor(primaryTextColor),
            highlightColor: UIColor(themeStore.accentGold),
            baseFont: themeStore.uiFont(size: 16, weight: .regular),
            highlightFont: themeStore.uiFont(size: 16, weight: .bold)
        )
    }
}

struct ShareWordPosterView: View {
    let word: StoredWord
    @ObservedObject var themeStore: ThemeStore
    var width: CGFloat = 360
    var height: CGFloat? = nil
    var useThemeGradient: Bool = false
    var showsBrand: Bool = true

    private var storiesCardWidth: CGFloat { 310 }
    private var storiesSideInset: CGFloat { 16 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if useThemeGradient {
                    LinearGradient(
                        colors: [Self.gradientTop(themeStore), Self.gradientBottom(themeStore)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    themeStore.appBg
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 16) {
                if showsBrand {
                    Text("Droword")
                        .font(themeStore.medium(useThemeGradient ? 22 : 15))
                        .foregroundStyle(useThemeGradient ? Color.white : themeStore.secondaryText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, useThemeGradient ? 0 : DesignSpacing.md)
                }

                ShareWordCardView(
                    word: word,
                    themeStore: themeStore,
                    cardWidth: useThemeGradient ? storiesCardWidth : width
                )

                Spacer(minLength: 0)
            }
            .padding(.top, useThemeGradient ? 56 : 20)
            .padding(.leading, useThemeGradient ? storiesSideInset : 0)
            .padding(.trailing, useThemeGradient ? max(0, width - storiesSideInset - storiesCardWidth) : 0)
            .padding(.bottom, useThemeGradient ? 48 : 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .environmentObject(themeStore)
    }

    static func gradientTop(_ themeStore: ThemeStore) -> Color {
        switch themeStore.palette {
        case .colorful: return Color(red: 0.29, green: 0.50, blue: 0.77)
        case .duolingo: return Color(red: 0.345, green: 0.800, blue: 0.008)
        case .glass: return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .custom: return themeStore.mainAccentColor
        }
    }

    static func gradientBottom(_ themeStore: ThemeStore) -> Color {
        switch themeStore.palette {
        case .colorful: return Color(red: 0.76, green: 0.37, blue: 0.51)
        case .duolingo: return Color(red: 0.10, green: 0.54, blue: 0.43)
        case .glass: return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .custom: return themeStore.accentPink
        }
    }
}

extension ShareWordCardView {
    static func tagColor(for tag: String) -> Color {
        switch tag {
        case "Travel", "Suggested": return Color.accentBlue
        case "Movie": return Color.accentPink
        case "Street": return Color.accentPurple
        case "Social media": return Color.accentGold
        case "Basics": return Color.accentGold
        case "Food": return Color.accentGreen
        case "Shopping": return Color.accentPurple
        case "Daily life": return Color.accentRed
        default:
            if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }),
               let color = Color(fromHexString: custom.colorHex) {
                return color
            }
            return Color.gray
        }
    }

    static func renderImage(for word: StoredWord, themeStore: ThemeStore, cardWidth: CGFloat = 360) -> UIImage? {
        let posterWidth = cardWidth
        let view = ShareWordPosterView(
            word: word,
            themeStore: themeStore,
            width: posterWidth,
            height: nil,
            useThemeGradient: false,
            showsBrand: true
        )
        .environmentObject(themeStore)

        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        controller.safeAreaRegions = SafeAreaRegions()

        let fitted = controller.sizeThatFits(
            in: CGSize(width: posterWidth, height: CGFloat.greatestFiniteMagnitude)
        )
        let size = CGSize(width: posterWidth, height: max(fitted.height, 280))
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

#Preview("Card") {
    let theme = ThemeStore()
    return ShareWordCardView(
        word: StoredWord(
            word: "hola",
            type: "interjection",
            translation: "hello",
            example: "¡Hola! ¿Cómo estás?",
            transcription: "ˈola",
            tag: "Travel",
            fromLanguage: "Español",
            toLanguage: "English",
            synonyms: ["hi", "hey"],
            reaction: "🔥"
        ),
        themeStore: theme
    )
    .padding()
    .background(theme.appBg)
    .environmentObject(theme)
}

#Preview("Poster") {
    let theme = ThemeStore()
    return ShareWordPosterView(
        word: StoredWord(
            word: "hola",
            type: "interjection",
            translation: "hello",
            example: "¡Hola! ¿Cómo estás?",
            explanation: "A greeting used when meeting someone.",
            transcription: "ˈola",
            tag: "Travel",
            fromLanguage: "Español",
            toLanguage: "English",
            synonyms: ["hi", "hey"],
            reaction: "🔥"
        ),
        themeStore: theme,
        width: 360,
        height: 640,
        useThemeGradient: false,
        showsBrand: true
    )
    .environmentObject(theme)
}
