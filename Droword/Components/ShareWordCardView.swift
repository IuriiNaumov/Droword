import SwiftUI

struct ShareWordCardView: View {
    let word: StoredWord
    let backgroundColor: Color
    let isDark: Bool

    private var primaryText: Color { isDark ? .white : .mainBlack }
    private var secondaryText: Color { isDark ? Color.white.opacity(0.85) : .mainBlack.opacity(0.8) }
    private var subtleText: Color { isDark ? Color.white.opacity(0.6) : Color.mainGrey }

    private var isGolden: Bool { word.tag == "Golden" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let tag = word.tag, !tag.isEmpty {
                Text(tag)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(isDark ? Color.white.opacity(0.9) : darkerShade(of: backgroundColor, by: 0.45))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(backgroundColor.opacity(isDark ? 0.5 : 0.32))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(darkerShade(of: backgroundColor, by: 0.15), lineWidth: 1.5)
                    )
                    .padding(.bottom, 2)
            }

            Text(word.word)
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let transcription = word.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(secondaryText)
            }

            if !word.type.isEmpty {
                Text(word.type.capitalized)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(secondaryText)
                    .padding(.bottom, 2)
            }

            if let translation = word.translation, !translation.isEmpty {
                Text(translation)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(primaryText)
            }

            if let example = word.example, !example.isEmpty {
                Text(highlightedExample(example: example, target: word.word))
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let explanation = word.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(primaryText)
            }

            if let breakdown = word.breakdown, !breakdown.isEmpty {
                Text(breakdown)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(primaryText)
            }

            if let comment = word.comment, !comment.isEmpty {
                Text(comment)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(isDark ? Color.white.opacity(0.75) : Color.mainGrey)
                    .padding(.top, 4)
            }

            HStack {
                Spacer()
                Text("Droword")
                    .font(.custom("Poppins-Bold", size: 13))
                    .foregroundColor(subtleText)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 340, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func highlightedExample(example: String, target: String) -> AttributedString {
        var attr = AttributedString(example)
        let lowerExample = example.lowercased()
        let lowerTarget = target.lowercased()

        guard let range = lowerExample.range(of: lowerTarget) else { return attr }

        let startOK: Bool = {
            if range.lowerBound == lowerExample.startIndex { return true }
            let prev = lowerExample.index(before: range.lowerBound)
            return !lowerExample[prev].isLetter && !lowerExample[prev].isNumber
        }()

        let endOK: Bool = {
            if range.upperBound == lowerExample.endIndex { return true }
            let next = range.upperBound
            return !lowerExample[next].isLetter && !lowerExample[next].isNumber
        }()

        if startOK && endOK,
           let attrStart = AttributedString.Index(range.lowerBound, within: attr),
           let attrEnd = AttributedString.Index(range.upperBound, within: attr) {
            let highlightRange = attrStart..<attrEnd
            attr[highlightRange].foregroundColor = isGolden ? .accentColor : .orange
            attr[highlightRange].font = .custom("Poppins-Bold", size: 16)
        }
        return attr
    }
}

extension ShareWordCardView {
    static func cardColor(for word: StoredWord, themeStore: ThemeStore) -> Color {
        guard let tag = word.tag, !tag.isEmpty else {
            return Color(.secondarySystemBackground)
        }
        switch tag {
        case "Chat": return themeStore.accentBlue
        case "Travel": return themeStore.accentGreen
        case "Street": return themeStore.accentPink
        case "Movies": return themeStore.accentPurple
        case "Golden": return themeStore.goldenColor
        default:
            if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }) {
                return themeStore.resolvedTagColor(custom.colorHex)
            }
            return Color(.secondarySystemBackground)
        }
    }

    static func renderImage(for word: StoredWord, themeStore: ThemeStore) -> UIImage? {
        let bgColor = cardColor(for: word, themeStore: themeStore)
        let isDark = UIColor(bgColor).isDarkColor

        let view = ShareWordCardView(word: word, backgroundColor: bgColor, isDark: isDark)

        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        controller.safeAreaRegions = SafeAreaRegions()

        let targetSize = controller.sizeThatFits(in: CGSize(width: 340, height: CGFloat.greatestFiniteMagnitude))
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

private extension UIColor {
    var isDarkColor: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum < 0.5
    }
}
