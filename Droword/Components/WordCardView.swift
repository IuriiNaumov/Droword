import SwiftUI
import AVFoundation
import UIKit

extension Notification.Name {
    static let dismissReactionPicker = Notification.Name("dismissReactionPicker")
}

struct WordCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let word: String
    let translation: String?
    let type: String?
    let example: String?
    let transcription: String?
    let comment: String?
    let explanation: String?
    let breakdown: String?
    let tag: String?
    let examples: [String]
    let collocations: [String]
    let synonyms: [String]
    let antonyms: [String]
    let mnemonic: String?
    let reaction: String?
    let storedWord: StoredWord?
    let onDelete: () -> Void
    let onReaction: ((String?) -> Void)?

    static let availableReactions = ["❤️", "👍", "🔥", "⭐️", "🤔", "😅"]

    private static let revealTransition: AnyTransition =
        .opacity.combined(with: .offset(y: -8))

    init(word: String, translation: String?, type: String?, example: String?, transcription: String?, comment: String?, explanation: String?, breakdown: String?, tag: String?, examples: [String] = [], collocations: [String] = [], synonyms: [String] = [], antonyms: [String] = [], mnemonic: String? = nil, reaction: String? = nil, storedWord: StoredWord? = nil, onDelete: @escaping () -> Void, onReaction: ((String?) -> Void)? = nil) {
        self.word = word
        self.translation = translation
        self.type = type
        self.example = example
        self.transcription = transcription
        self.comment = comment
        self.explanation = explanation
        self.breakdown = breakdown
        self.tag = tag
        self.examples = examples
        self.collocations = collocations
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.mnemonic = mnemonic
        self.reaction = reaction
        self.storedWord = storedWord
        self.onDelete = onDelete
        self.onReaction = onReaction
    }



    @State private var cardID = UUID()
    @State private var isExpanded = true
    @State private var isPlaying = false
    @State private var showPremiumWall = false
    @State private var showAllExamples = false
    @State private var showReactionPicker = false
    @State private var showEmojiKeyboard = false
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var highlightedExample: AttributedString = ""
    @State private var highlightedExtraExamples: [AttributedString] = []
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?


    private var isSuggested: Bool { tag == "Suggested" }

    private var backgroundColor: Color {
        themeStore.cardBg
    }

    private var primaryTextColor: Color {
        themeStore.mainText
    }

    private var secondaryTextColor: Color {
        themeStore.mainText.opacity(0.8)
    }

    private var pickerReactions: [String] {
        guard let reaction = reaction, !Self.availableReactions.contains(reaction) else {
            return Self.availableReactions
        }
        return [reaction] + Self.availableReactions
    }

    var body: some View {
        cardContent
            .overlay {
                // Dim the card behind the reaction picker to focus attention on
                // the emoji, iMessage-style. Tapping the scrim dismisses it.
                if showReactionPicker {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.4 : 0.14))
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                showReactionPicker = false
                            }
                        }
                }
            }
            .overlay(alignment: .topTrailing) {
                if let reaction = reaction {
                    Button {
                        Haptics.lightImpact(intensity: 0.4)
                        if !showReactionPicker {
                            NotificationCenter.default.post(name: .dismissReactionPicker, object: cardID)
                        }
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                            showReactionPicker.toggle()
                        }
                    } label: {
                        Text(reaction)
                            .font(.system(size: 24))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? themeStore.accentBlue : themeStore.accentBlueSoft)
                            )
                    }
                    .buttonStyle(ReactionButtonStyle())
                    .offset(x: 8, y: -22)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.2, anchor: .center).combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
                }
            }
            .overlay(alignment: .top) {
                if showReactionPicker, onReaction != nil {
                    ReactionPickerBar(
                        reactions: pickerReactions,
                        current: reaction,
                        onSelect: { emoji in
                            Haptics.lightImpact()
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
                                onReaction?(reaction == emoji ? nil : emoji)
                                showReactionPicker = false
                            }
                        },
                        onCustom: {
                            Haptics.lightImpact()
                            showEmojiKeyboard = true
                        }
                    )
                    .transition(.scale(scale: 0.65, anchor: .bottomTrailing).combined(with: .opacity))
                    .offset(y: -52)
                    .zIndex(10)
                    .overlay {
                        EmojiKeyboardField(isPresented: $showEmojiKeyboard) { emoji in
                            Haptics.lightImpact()
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
                                onReaction?(emoji)
                                showReactionPicker = false
                            }
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(word), \(translation ?? "")"))
            .contextMenu {
                Button {
                    UIPasteboard.general.string = word
                    NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
                } label: {
                    Label(word, systemImage: "doc.on.doc")
                }

                if let translation = translation, !translation.isEmpty {
                    Button {
                        UIPasteboard.general.string = translation
                        NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
                    } label: {
                        Label(translation, systemImage: "doc.on.doc")
                    }
                }

                if let example = example, !example.isEmpty {
                    Button {
                        UIPasteboard.general.string = example
                        NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
                    } label: {
                        Label("Example", systemImage: "text.quote")
                    }
                }

                Button {
                    var parts: [String] = [word]
                    if let transcription = transcription, !transcription.isEmpty { parts.append(transcription) }
                    if let translation = translation, !translation.isEmpty { parts.append(translation) }
                    if let type = type, !type.isEmpty { parts.append(type.capitalized) }
                    if let example = example, !example.isEmpty { parts.append(example) }
                    if let explanation = explanation, !explanation.isEmpty { parts.append(explanation) }
                    if let comment = comment, !comment.isEmpty { parts.append(comment) }
                    UIPasteboard.general.string = parts.joined(separator: "\n")
                    NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
                } label: {
                    Label("Copy all", systemImage: "doc.on.doc.fill")
                }
            }
        .animation(.spring(response: 0.4, dampingFraction: 0.58), value: reaction)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: showReactionPicker)
        .padding(.top, reaction != nil ? 14 : 12)
        .padding(.bottom, 0)
        .onTapGesture(count: 2) {
            guard onReaction != nil else { return }
            Haptics.lightImpact(intensity: 0.4)
            NotificationCenter.default.post(name: .dismissReactionPicker, object: cardID)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                showReactionPicker = true
            }
        }
        .onTapGesture {
            // Any tap on a card dismisses an open reaction picker on other cards.
            NotificationCenter.default.post(name: .dismissReactionPicker, object: cardID)
            if showReactionPicker {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    showReactionPicker = false
                }
                return
            }
            if isExpanded {
                Haptics.lightImpact(intensity: 0.4)
            } else {
                Haptics.lightImpact(intensity: 0.3)
            }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
                isExpanded.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissReactionPicker)) { note in
            guard showReactionPicker else { return }
            if let senderID = note.object as? UUID, senderID == cardID { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                showReactionPicker = false
            }
        }
        .onDisappear {
            // Reset the picker when the card scrolls out of view or its tab
            // is switched away, so it never lingers when the card returns.
            showReactionPicker = false
        }
        .onAppear {
            if let example = example {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word)
            } else {
                highlightedExample = ""
            }
            highlightedExtraExamples = examples.dropFirst().map {
                Self.makeHighlightedExample(comment: $0, word: word)
            }
        }
        .onChange(of: example) { _, newValue in
            if let example = newValue {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word)
            } else {
                highlightedExample = ""
            }
        }
        .onChange(of: examples) { _, newValue in
            highlightedExtraExamples = newValue.dropFirst().map {
                Self.makeHighlightedExample(comment: $0, word: word)
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {

            if let tag = tag, !tag.isEmpty {
                Text(LocalizedStringKey(tag))
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.colorForTag(tag))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(themeStore.colorForTag(tag), lineWidth: 1)
                    )
                    .padding(.bottom, 2)
            }

            headerRow

            if let transcription = transcription, !transcription.isEmpty {
                Text("[\(transcription)]")
                    .font(themeStore.regular(14))
                    .foregroundStyle(secondaryTextColor)
            }

            if let type = type, !type.isEmpty, isExpanded {
                Text(type.capitalized)
                    .font(themeStore.regular(14))
                    .foregroundStyle(secondaryTextColor)
                    .padding(.bottom, 2)
                    .transition(Self.revealTransition)
            }

            if let translation = translation {
                Text(translation)
                    .font(themeStore.regular(16))
                    .foregroundStyle(primaryTextColor)
            }

            if isExpanded {
                if let _ = example {
                    Text(highlightedExample)
                        .font(themeStore.regular(16))
                        .foregroundStyle(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(Self.revealTransition)

                    if examples.count > 1 {
                        if showAllExamples {
                            ForEach(Array(highlightedExtraExamples.enumerated()), id: \.offset) { _, attr in
                                Text(attr)
                                    .font(themeStore.regular(16))
                                    .foregroundStyle(primaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .transition(Self.revealTransition)
                            }
                        }

                        Button {
                            Haptics.lightImpact(intensity: 0.3)
                            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
                                showAllExamples.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(showAllExamples ? "Hide examples" : "More examples")
                                    .font(themeStore.medium(13))
                                Image(systemName: showAllExamples ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(themeStore.mainAccentColor)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }

                if let explanation = explanation {
                    Text(explanation)
                        .font(themeStore.regular(16))
                        .foregroundStyle(primaryTextColor)
                        .transition(Self.revealTransition)
                }

                if let breakdown = breakdown {
                    Text(breakdown)
                        .font(themeStore.regular(16))
                        .foregroundStyle(primaryTextColor)
                        .transition(Self.revealTransition)
                }

                if !collocations.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Common phrases")
                            .font(themeStore.medium(13))
                            .foregroundStyle(themeStore.secondaryText)
                        Text(collocations.joined(separator: "  ·  "))
                            .font(themeStore.regular(15))
                            .foregroundStyle(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                    .transition(Self.revealTransition)
                }

                if !synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Synonyms")
                            .font(themeStore.medium(13))
                            .foregroundStyle(themeStore.secondaryText)
                        Text(synonyms.joined(separator: "  ·  "))
                            .font(themeStore.regular(15))
                            .foregroundStyle(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                    .transition(Self.revealTransition)
                }

                if !antonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opposites")
                            .font(themeStore.medium(13))
                            .foregroundStyle(themeStore.secondaryText)
                        Text(antonyms.joined(separator: "  ·  "))
                            .font(themeStore.regular(15))
                            .foregroundStyle(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                    .transition(Self.revealTransition)
                }

                if let mnemonic = mnemonic, !mnemonic.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(themeStore.accentGold)
                            .padding(.top, 1)
                        Text(mnemonic)
                            .font(themeStore.regular(14))
                            .foregroundStyle(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                    .transition(Self.revealTransition)
                }

                if let comment = comment, !comment.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14))
                            .foregroundStyle(themeStore.secondaryText.opacity(0.7))
                            .padding(.top, 2)
                        Text(comment)
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.secondaryText)
                    }
                    .padding(.top, 4)
                    .transition(Self.revealTransition)
                }
            }

            HStack {
                if storedWord != nil {
                    Menu {
                        Button {
                            shareWord()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            shareToStories()
                        } label: {
                            Label {
                                Text("Instagram Stories")
                            } icon: {
                                Image("instagram")
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundStyle(secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Share word"))
                }
                Spacer()
                Button(action: { Haptics.warning(); onDelete() }) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(Color.accentRed)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Delete word"))
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : backgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 20))
        .shadow(color: themeStore.cardShadowColor, radius: themeStore.cardShadowRadius, x: 0, y: 3)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {

            Text(word)
                .font(themeStore.bold(24))
                .foregroundStyle(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: playAudio) {
                SoundWavesView(isPlaying: isPlaying)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Play pronunciation"))
            .accessibilityHint(Text("Plays audio for \(word)"))
            .padding(.top, 6)

        }
        .frame(maxWidth: .infinity)
    }

    private func playAudio() {
        TTSPlayer.play(
            word: word,
            isPremium: isPremium,
            onNeedsPremium: { showPremiumWall = true },
            onPlayingChanged: { isPlaying = $0 }
        )
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

    private func shareToStories() {
        guard let stored = storedWord else { return }
        Haptics.lightImpact()

        if InstagramStoriesShare.isInstagramInstalled {
            InstagramStoriesShare.shareToInstagramStories(word: stored, themeStore: themeStore)
        } else {
            // Fallback: share Stories-sized image via regular share sheet
            guard let image = InstagramStoriesShare.renderStoriesImage(for: stored, themeStore: themeStore) else { return }

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
    }

    private static func makeHighlightedExample(comment: String, word: String) -> AttributedString {
        HighlightedExample.make(example: comment, word: word)
    }
}

/// Button style that gives reactions a tactile "squish" on press, like iMessage.
private struct ReactionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// iMessage-style reaction bar: the emoji cascade in one-by-one with a springy
/// pop, and each responds to touch with a squish.
private struct ReactionPickerBar: View {
    let reactions: [String]
    let current: String?
    let onSelect: (String) -> Void
    let onCustom: () -> Void

    @EnvironmentObject private var themeStore: ThemeStore
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(reactions.enumerated()), id: \.element) { index, emoji in
                Button {
                    onSelect(emoji)
                } label: {
                    Text(emoji)
                        .font(.system(size: 28))
                        .padding(4)
                        .background(
                            Circle()
                                .fill(current == emoji ? themeStore.accentBlueSoft : Color.clear)
                        )
                }
                .buttonStyle(ReactionButtonStyle())
                .scaleEffect(appeared ? 1 : 0.2)
                .opacity(appeared ? 1 : 0)
                .animation(cascade(index), value: appeared)
            }

            Button {
                onCustom()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeStore.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(themeStore.mainText.opacity(0.08))
                    )
            }
            .buttonStyle(ReactionButtonStyle())
            .scaleEffect(appeared ? 1 : 0.2)
            .opacity(appeared ? 1 : 0)
            .animation(cascade(reactions.count), value: appeared)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThickMaterial)
        )
        .onAppear { appeared = true }
    }

    /// Springy pop with a per-index delay so items enter left-to-right.
    private func cascade(_ index: Int) -> Animation {
        .spring(response: 0.34, dampingFraction: 0.6)
        .delay(Double(index) * 0.035)
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
            tag: "Suggested",
            reaction: "😅",
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
