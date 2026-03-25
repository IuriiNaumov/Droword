import SwiftUI
import AVFoundation
import UIKit

struct WordCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let word: String
    let translation: String?
    let type: String?
    let example: String?
    let transcription: String?
    let comment: String?
    let explanation: String?
    let breakdown: String?
    let tag: String?
    let storedWord: StoredWord?
    let onDelete: () -> Void

    init(word: String, translation: String?, type: String?, example: String?, transcription: String?, comment: String?, explanation: String?, breakdown: String?, tag: String?, storedWord: StoredWord? = nil, onDelete: @escaping () -> Void) {
        self.word = word
        self.translation = translation
        self.type = type
        self.example = example
        self.transcription = transcription
        self.comment = comment
        self.explanation = explanation
        self.breakdown = breakdown
        self.tag = tag
        self.storedWord = storedWord
        self.onDelete = onDelete
    }

    private func colorForTag(_ tag: String) -> Color {
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
            return themeStore.cardBg
        }
    }

    @State private var isExpanded = true
    @State private var isPlaying = false
    @State private var showPremiumWall = false
    @AppStorage("isPremium") private var isPremium: Bool = false
    @State private var highlightedExample: AttributedString = ""
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    private var isGolden: Bool { tag == "Golden" }

    private var backgroundColor: Color {
        if let tag = tag, !tag.isEmpty {
            return colorForTag(tag)
        }
        return themeStore.cardBg
    }

    private var isDarkBackground: Bool {
        backgroundColor.isDarkColor
    }

    private var hasTagColor: Bool {
        tag != nil && !tag!.isEmpty
    }

    private var primaryTextColor: Color {
        if isDarkBackground { return .white }
        if themeStore.isDuolingo && hasTagColor {
            return darkerShade(of: backgroundColor, by: 0.45)
        }
        return themeStore.mainText
    }

    private var secondaryTextColor: Color {
        if isDarkBackground { return Color.white.opacity(0.85) }
        if themeStore.isDuolingo && hasTagColor {
            return darkerShade(of: backgroundColor, by: 0.35)
        }
        return themeStore.mainText.opacity(0.8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            if let tag = tag, !tag.isEmpty {
                Text(tag)
                    .font(themeStore.medium(15))
                    .foregroundColor(isDarkBackground ? Color.white.opacity(0.9) : darkerShade(of: colorForTag(tag), by: 0.45))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colorForTag(tag).opacity(isDarkBackground ? 0.5 : 0.32))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(darkerShade(of: backgroundColor, by: 0.15), lineWidth: 1.5)
                    )
                    .padding(.bottom, 2)
            }

            headerRow

            if let transcription = transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(themeStore.regular(14))
                    .foregroundColor(secondaryTextColor)
            }

            if let type = type, !type.isEmpty, isExpanded {
                Text(type.capitalized)
                    .font(themeStore.regular(14))
                    .foregroundColor(secondaryTextColor)
                    .padding(.bottom, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let translation = translation {
                Text(translation)
                    .font(themeStore.regular(16))
                    .foregroundColor(primaryTextColor)
            }

            if isExpanded {
                if let _ = example {
                    Text(highlightedExample)
                        .font(themeStore.regular(16))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let explanation = explanation {
                    Text(explanation)
                        .font(themeStore.regular(16))
                        .foregroundColor(primaryTextColor)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let breakdown = breakdown {
                    Text(breakdown)
                        .font(themeStore.regular(16))
                        .foregroundColor(primaryTextColor)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let comment = comment, !comment.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14))
                            .foregroundColor(isDarkBackground ? Color.white.opacity(0.6) : themeStore.secondaryText.opacity(0.7))
                            .padding(.top, 2)
                        Text(comment)
                            .font(themeStore.regular(16))
                            .foregroundColor(isDarkBackground ? Color.white.opacity(0.75) : themeStore.secondaryText)
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            HStack {
                if storedWord != nil {
                    Button(action: shareWord) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button(action: { Haptics.warning(); onDelete() }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 12)
        .onTapGesture {
            if isExpanded {
                Haptics.lightImpact(intensity: 0.4)
            } else {
                Haptics.lightImpact(intensity: 0.3)
            }
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
                isExpanded.toggle()
            }
        }
        .onAppear {
            if let example = example {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word, isGolden: isGolden)
            } else {
                highlightedExample = ""
            }
        }
        .onChange(of: example) { _, newValue in
            if let example = newValue {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word, isGolden: isGolden)
            } else {
                highlightedExample = ""
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {

            Text(word)
                .font(themeStore.bold(24))
                .foregroundColor(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: playAudio) {
                SoundWavesView(isPlaying: isPlaying)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

        }
        .frame(maxWidth: .infinity)
    }

    private func playAudio() {
        guard isPremium || DailyLimitsManager.canPlayTTS else {
            showPremiumWall = true
            return
        }
        if !isPremium {
            DailyLimitsManager.recordTTS()
        }
        Task {
            Haptics.selection()
            isPlaying = true
            await AudioManager.shared.play(word: word)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation {
                isPlaying = false
            }
        }
    }

    private func shareWord() {
        guard let stored = storedWord else { return }
        Haptics.lightImpact()

        guard let image = ShareWordCardView.renderImage(for: stored, themeStore: themeStore) else { return }

        let text = "\(stored.word) — \(stored.translation ?? "")"
        let items: [Any] = [image, text]

        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.keyWindow?.rootViewController {
            if let popover = ac.popoverPresentationController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            root.present(ac, animated: true)
        }
    }

    private static func makeHighlightedExample(comment: String, word: String, isGolden: Bool) -> AttributedString {
        var attributedString = AttributedString(comment)
        if let range = attributedString.range(of: word, options: .caseInsensitive) {
            attributedString[range].foregroundColor = isGolden ? .accentColor : .orange
            attributedString[range].font = .custom("Poppins-Bold", size: 16)
        }
        return attributedString
    }
}

private extension Color {
    var isDarkColor: Bool {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum < 0.5
    }
}

#Preview {
    VStack(spacing: 20) {

        WordCardView(
            word: "Sabroso",
            translation: "Вкусный",
            type: "adjective",
            example: "Este plato es muy sabroso y delicioso.",
            transcription: nil,
            comment: "Мое любимое слово!",
            explanation: "Используется для описания вкусной еды или напитков.",
            breakdown: "Происходит от sabor (вкус) + -oso (обладающий качеством)",
            tag: "Golden",
            onDelete: {}
        )

        WordCardView(
            word: "Chido",
            translation: "Круто",
            type: "adjective",
            example: "La fiesta estuvo chido y divertida.",
            transcription: nil,
            comment: nil,
            explanation: "Мексиканский разговорный термин, означающий что-то классное или приятное.",
            breakdown: nil,
            tag: "Slang",
            onDelete: {}
        )

        WordCardView(
            word: "食べ物",
            translation: "Еда",
            type: "noun",
            example: "この食べ物はとてもおいしいです。",
            transcription: nil,
            comment: nil,
            explanation: "Общее слово для обозначения еды или продуктов питания.",
            breakdown: "食 (есть) + べる (глагольная основа) + 物 (вещь) — буквально: 'то, что едят'",
            tag: "Chat",
            onDelete: {}
        )

    }
    .padding()
}
