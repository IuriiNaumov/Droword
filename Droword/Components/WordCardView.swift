import SwiftUI
import AVFoundation
import UIKit

extension Notification.Name {
    static let dismissReactionPicker = Notification.Name("dismissReactionPicker")
}

struct WordCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
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
    @State private var isHoldingAudio = false
    @State private var holdStartedAt: Date?
    @State private var ignoreCardTapUntil: Date?
    @State private var showPremiumWall = false
    @State private var showAllExamples = false
    @State private var showReactionPicker = false
    @State private var showEmojiKeyboard = false
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var highlightedExample: AttributedString = ""
    @State private var highlightedExtraExamples: [AttributedString] = []
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showEditWord = false
    @ObservedObject private var network = NetworkMonitor.shared

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
            .overlay(alignment: .topTrailing) {
                if let reaction = reaction {
                    Button {
                        openReactionPicker()
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
                    .zIndex(20)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.2, anchor: .center).combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(word), \(translation ?? "")"))
            .accessibilityHint(Text("Double tap for heart. Press and hold for reactions and actions"))
        .animation(.spring(response: 0.4, dampingFraction: 0.58), value: reaction)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: showReactionPicker)
        .padding(.top, reaction != nil ? 14 : 12)
        .padding(.bottom, 0)
        .zIndex(reaction != nil ? 5 : 0)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45, maximumDistance: 12)
                .onEnded { _ in
                    openReactionPicker()
                }
        )
        .onTapGesture(count: 2) {
            guard onReaction != nil else { return }
            if let until = ignoreCardTapUntil, Date() < until { return }

            NotificationCenter.default.post(name: .dismissReactionPicker, object: cardID)
            let heart = "❤️"
            if reaction == heart {
                Haptics.softTap()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
                    onReaction?(nil)
                }
            } else {
                Haptics.success()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
                    onReaction?(heart)
                }
            }
        }
        .onTapGesture {
            if let until = ignoreCardTapUntil, Date() < until { return }

            NotificationCenter.default.post(name: .dismissReactionPicker, object: cardID)
            if isExpanded {
                Haptics.cardCollapse()
            } else {
                Haptics.cardExpand()
            }
            withAnimation(DesignMotion.card) {
                isExpanded.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissReactionPicker)) { note in
            guard showReactionPicker else { return }
            if let senderID = note.object as? UUID, senderID == cardID { return }
            closeReactionPicker()
        }
        .onDisappear {
            showReactionPicker = false
            showEmojiKeyboard = false
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
        .fullScreenCover(isPresented: $showReactionPicker) {
            WordCardFocusOverlay(
                word: word,
                translation: translation,
                type: type,
                tag: tag,
                reactions: pickerReactions,
                currentReaction: reaction,
                canEdit: storedWord != nil,
                canShare: storedWord != nil,
                allowsReactions: onReaction != nil,
                onReaction: { emoji in
                    if reaction == emoji {
                        Haptics.softTap()
                        onReaction?(nil)
                    } else {
                        Haptics.success()
                        onReaction?(emoji)
                    }
                    closeReactionPicker()
                },
                onCustomReaction: {
                    Haptics.softTap()
                    showEmojiKeyboard = true
                },
                onCopy: {
                    UIPasteboard.general.string = word
                    closeReactionPicker()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
                    }
                },
                onCopyTranslation: {
                    guard let translation, !translation.isEmpty else { return }
                    UIPasteboard.general.string = translation
                    closeReactionPicker()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
                    }
                },
                onCopyAll: {
                    closeReactionPicker()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        copyAllFields()
                    }
                },
                onShare: {
                    closeReactionPicker()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        shareWord()
                    }
                },
                onEdit: {
                    closeReactionPicker()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showEditWord = true
                    }
                },
                onDelete: {
                    closeReactionPicker()
                    Haptics.warning()
                    onDelete()
                },
                onDismiss: {
                    closeReactionPicker()
                }
            )
            .environmentObject(themeStore)
            .presentationBackground(.clear)
            .overlay {
                EmojiKeyboardField(isPresented: $showEmojiKeyboard) { emoji in
                    Haptics.success()
                    onReaction?(emoji)
                    closeReactionPicker()
                }
                .frame(width: 0, height: 0)
                .opacity(0)
            }
        }
        .sheet(isPresented: $showEditWord) {
            if let storedWord {
                EditWordView(word: storedWord)
                    .environmentObject(themeStore)
                    .environmentObject(store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .modernSheet()
            }
        }
    }

    private func openReactionPicker() {
        ignoreCardTapUntil = Date().addingTimeInterval(0.55)
        Haptics.open()
        NotificationCenter.default.post(name: .dismissReactionPicker, object: cardID)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showReactionPicker = true
        }
    }

    private func closeReactionPicker() {
        showEmojiKeyboard = false
        showReactionPicker = false
    }

    private func copyAllFields() {
        var parts: [String] = [word]
        if let transcription = transcription, !transcription.isEmpty { parts.append(transcription) }
        if let translation = translation, !translation.isEmpty { parts.append(translation) }
        if let type = type, !type.isEmpty { parts.append(type.capitalized) }
        if let example = example, !example.isEmpty { parts.append(example) }
        if let explanation = explanation, !explanation.isEmpty { parts.append(explanation) }
        if let comment = comment, !comment.isEmpty { parts.append(comment) }
        UIPasteboard.general.string = parts.joined(separator: "\n")
        NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {

            if let tag = tag, !tag.isEmpty {
                Text(BuiltInTag.displayName(tag))
                    .font(themeStore.medium(11))
                    .foregroundStyle(
                        themeStore.isGlass
                            ? themeStore.mainText
                            : (themeStore.isMonochrome ? themeStore.mainText : themeStore.colorForTag(tag))
                    )
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                themeStore.isGlass
                                    ? themeStore.colorForTag(tag).opacity(0.28)
                                    : themeStore.colorForTag(tag).opacity(themeStore.isMonochrome ? 0.18 : 0.2)
                            )
                    )
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
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
                            Haptics.softTap()
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
        }
        .padding(DesignSpacing.md)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : backgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {

            Text(word)
                .font(themeStore.medium(24))
                .tracking(-0.2)
                .foregroundStyle(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            SoundWavesView(isPlaying: isPlaying)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .opacity(network.isConnected ? 1 : 0.35)
                .allowsHitTesting(network.isConnected)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard network.isConnected else { return }
                            guard !isHoldingAudio else { return }
                            ignoreCardTapUntil = Date().addingTimeInterval(0.45)
                            holdStartedAt = Date()
                            isHoldingAudio = true
                            TTSPlayer.beginHold(
                                word: word,
                                isPremium: isPremium,
                                onNeedsPremium: { showPremiumWall = true },
                                onPlayingChanged: { isPlaying = $0 }
                            )
                        }
                        .onEnded { _ in
                            ignoreCardTapUntil = Date().addingTimeInterval(0.45)
                            guard isHoldingAudio else { return }
                            let elapsed = Date().timeIntervalSince(holdStartedAt ?? Date())
                            isHoldingAudio = false
                            holdStartedAt = nil
                            TTSPlayer.endHold(onPlayingChanged: { isPlaying = $0 })
                            if elapsed < 0.22 {
                                playAudio()
                            }
                        }
                )
                .accessibilityLabel(Text("Pronunciation"))
                .accessibilityHint(
                    Text(network.isConnected
                         ? "Tap to play, or hold to hear while pressed"
                         : "Needs an internet connection")
                )
        }
        .frame(maxWidth: .infinity)
    }

    private func playAudio() {
        guard network.isConnected else { return }
        TTSPlayer.play(
            word: word,
            isPremium: isPremium,
            onNeedsPremium: { showPremiumWall = true },
            onPlayingChanged: { isPlaying = $0 }
        )
    }

    private func shareWord() {
        guard let stored = storedWord else { return }
        Haptics.softTap()

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

    private static func makeHighlightedExample(comment: String, word: String) -> AttributedString {
        HighlightedExample.make(example: comment, word: word)
    }
}

private struct WordCardFocusOverlay: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let word: String
    let translation: String?
    let type: String?
    let tag: String?
    let reactions: [String]
    let currentReaction: String?
    let canEdit: Bool
    let canShare: Bool
    let allowsReactions: Bool

    let onReaction: (String) -> Void
    let onCustomReaction: () -> Void
    let onCopy: () -> Void
    let onCopyTranslation: () -> Void
    let onCopyAll: () -> Void
    let onShare: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black
                .opacity(appeared ? (colorScheme == .dark ? 0.55 : 0.28) : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14) {
                if allowsReactions {
                    ReactionPickerBar(
                        reactions: reactions,
                        current: currentReaction,
                        onSelect: onReaction,
                        onCustom: onCustomReaction
                    )
                    .scaleEffect(appeared ? 1 : 0.88)
                    .opacity(appeared ? 1 : 0)
                }

                collapsedCard
                    .scaleEffect(appeared ? 1 : 0.94)
                    .opacity(appeared ? 1 : 0)

                actionMenu
                    .frame(maxWidth: 200, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(appeared ? 1 : 0.94)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 420)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    private var collapsedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let tag, !tag.isEmpty {
                Text(BuiltInTag.displayName(tag))
                    .font(themeStore.medium(11))
                    .foregroundStyle(
                        themeStore.isGlass
                            ? themeStore.mainText
                            : (themeStore.isMonochrome ? themeStore.mainText : themeStore.colorForTag(tag))
                    )
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                themeStore.isGlass
                                    ? themeStore.colorForTag(tag).opacity(0.28)
                                    : themeStore.colorForTag(tag).opacity(themeStore.isMonochrome ? 0.18 : 0.2)
                            )
                    )
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
            }

            Text(word)
                .font(themeStore.medium(24))
                .tracking(-0.2)
                .foregroundStyle(themeStore.mainText)
                .lineLimit(2)

            if let type, !type.isEmpty {
                Text(type.capitalized)
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.mainText.opacity(0.75))
            }

            if let translation, !translation.isEmpty {
                Text(translation)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.mainText)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        .shadow(color: .black.opacity(0.16), radius: 20, y: 10)
    }

    private var actionMenu: some View {
        VStack(spacing: 0) {
            menuRow(title: "Copy", systemImage: "doc.on.doc", action: onCopy)

            if !(translation ?? "").isEmpty {
                menuDivider
                menuRow(title: "Copy translation", systemImage: "character.textbox", action: onCopyTranslation)
            }

            menuDivider
            menuRow(title: "Copy all", systemImage: "square.on.square", action: onCopyAll)

            if canShare {
                menuDivider
                menuRow(title: "Share", systemImage: "square.and.arrow.up", action: onShare)
            }

            if canEdit {
                menuDivider
                menuRow(title: "Edit", systemImage: "square.and.pencil", action: onEdit)
            }

            menuDivider
            menuRow(title: "Delete", systemImage: "trash", destructive: true, action: onDelete)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.small, style: .continuous))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: DesignRadius.small))
        .shadow(color: Color.black.opacity(0.14), radius: 20, y: 10)
    }

    private var menuDivider: some View {
        Divider()
            .padding(.leading, 18)
    }

    private func menuRow(
        title: LocalizedStringKey,
        systemImage: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(title)
                    .font(themeStore.regular(17))
                    .foregroundStyle(destructive ? Color.accentRed : themeStore.mainText)

                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .regular))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(destructive ? Color.accentRed : themeStore.mainText)
                    .frame(width: 24, alignment: .trailing)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
    }
}

private struct ReactionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

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
        .clipShape(Capsule())
        .glassEffect(.regular.interactive(), in: .capsule)
        .onAppear { appeared = true }
    }

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
