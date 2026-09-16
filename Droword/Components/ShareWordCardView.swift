import SwiftUI

struct ShareWordCardView: View {
    let word: StoredWord
    let backgroundColor: Color
    var cardWidth: CGFloat = 340

    private var primaryText: Color { .mainBlack }
    private var secondaryText: Color { .mainBlack.opacity(0.8) }
    private var subtleText: Color { Color.mainGrey }

    private var isSuggested: Bool { word.tag == "Suggested" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let tag = word.tag, !tag.isEmpty {
                Text(LocalizedStringKey(tag))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Self.tagColor(for: tag))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 18)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Self.tagColor(for: tag).opacity(0.18))
                    )
                    .padding(.bottom, 2)
            }

            Text(word.word)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let transcription = word.transcription, !transcription.isEmpty {
                Text("[\(transcription)]")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(secondaryText)
            }

            if !word.type.isEmpty {
                Text(word.type.capitalized)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .padding(.bottom, 2)
            }

            if let translation = word.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(primaryText)
            }

            if let example = word.example, !example.isEmpty {
                Text(highlightedExample(example: example, target: word.word))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let explanation = word.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(primaryText)
            }

            if let breakdown = word.breakdown, !breakdown.isEmpty {
                Text(breakdown)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(primaryText)
            }

            if let comment = word.comment, !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.mainGrey)
                    .padding(.top, 4)
            }

            HStack {
                Spacer()
                Text("Droword")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(subtleText)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: cardWidth, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous))
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
            attr[highlightRange].foregroundColor = isSuggested ? .accentColor : .orange
            attr[highlightRange].font = .system(size: 16, weight: .bold, design: .rounded)
        }
        return attr
    }
}

extension ShareWordCardView {
    static func tagColor(for tag: String) -> Color {
        switch tag {
        case "Travel": return Color.accentBlue
        case "Suggested": return Color.accentBlue
        default:
            if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }),
               let color = Color(fromHexString: custom.colorHex) {
                return color
            }
            return Color.gray
        }
    }

    static func renderImage(for word: StoredWord, themeStore: ThemeStore, cardWidth: CGFloat = 340) -> UIImage? {
        let bgColor = Color(.secondarySystemBackground)

        let view = ShareWordCardView(word: word, backgroundColor: bgColor, cardWidth: cardWidth)

        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        controller.safeAreaRegions = SafeAreaRegions()

        let targetSize = controller.sizeThatFits(in: CGSize(width: cardWidth, height: CGFloat.greatestFiniteMagnitude))
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
