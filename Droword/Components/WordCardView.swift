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
    let examples: [String]
    let reaction: String?
    let storedWord: StoredWord?
    let onDelete: () -> Void
    let onReaction: ((String?) -> Void)?

    static let availableReactions = ["❤️", "👍", "🔥", "⭐️", "🤔", "😅"]

    init(word: String, translation: String?, type: String?, example: String?, transcription: String?, comment: String?, explanation: String?, breakdown: String?, tag: String?, examples: [String] = [], reaction: String? = nil, storedWord: StoredWord? = nil, onDelete: @escaping () -> Void, onReaction: ((String?) -> Void)? = nil) {
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
        self.reaction = reaction
        self.storedWord = storedWord
        self.onDelete = onDelete
        self.onReaction = onReaction
    }



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

    var body: some View {
        cardContent
            .overlay(alignment: .topTrailing) {
                if let reaction = reaction {
                    Button {
                        Haptics.lightImpact(intensity: 0.4)
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showReactionPicker.toggle()
                        }
                    } label: {
                        Text(reaction)
                            .font(.system(size: 24))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(themeStore.accentBlueSoft)
                            )
                    }
                    .buttonStyle(.plain)
                    .offset(x: 8, y: -22)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(alignment: .top) {
                if showReactionPicker, onReaction != nil {
                    HStack(spacing: 4) {
                        ForEach(Self.availableReactions, id: \.self) { emoji in
                            Button {
                                Haptics.lightImpact()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    onReaction?(reaction == emoji ? nil : emoji)
                                    showReactionPicker = false
                                }
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(reaction == emoji ? themeStore.accentBlueSoft : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            Haptics.lightImpact()
                            showEmojiKeyboard = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeStore.secondaryText)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(themeStore.mainText.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThickMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                    )
                    .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
                    .offset(y: -52)
                    .zIndex(10)
                    .overlay {
                        EmojiKeyboardField(isPresented: $showEmojiKeyboard) { emoji in
                            Haptics.lightImpact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: reaction)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showReactionPicker)
        .padding(.top, reaction != nil ? 14 : 12)
        .padding(.bottom, 0)
        .onTapGesture(count: 2) {
            guard onReaction != nil else { return }
            Haptics.lightImpact(intensity: 0.4)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                showReactionPicker.toggle()
            }
        }
        .onTapGesture {
            if showReactionPicker {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    showReactionPicker = false
                }
                return
            }
            if isExpanded {
                Haptics.lightImpact(intensity: 0.4)
            } else {
                Haptics.lightImpact(intensity: 0.3)
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                isExpanded.toggle()
            }
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
                    .foregroundColor(themeStore.colorForTag(tag))
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

                    if examples.count > 1 {
                        if showAllExamples {
                            ForEach(Array(highlightedExtraExamples.enumerated()), id: \.offset) { _, attr in
                                Text(attr)
                                    .font(themeStore.regular(16))
                                    .foregroundColor(primaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
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
                            .foregroundColor(themeStore.mainAccentColor)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
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
                            .foregroundColor(themeStore.secondaryText.opacity(0.7))
                            .padding(.top, 2)
                        Text(comment)
                            .font(themeStore.regular(16))
                            .foregroundColor(themeStore.secondaryText)
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
                            .foregroundColor(secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Share word"))
                }
                Spacer()
                Button(action: { Haptics.warning(); onDelete() }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color.accentRed)
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
                .fill(backgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            .accessibilityLabel(Text("Play pronunciation"))
            .accessibilityHint(Text("Plays audio for \(word)"))
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
            do {
                try await AudioManager.shared.playAndWait(text: word)
            } catch {
                #if DEBUG
                print("⚠️ Audio playback failed for '\(word)': \(error.localizedDescription)")
                #endif
            }
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
        var attributedString = AttributedString(comment)
        if let range = attributedString.range(of: word, options: .caseInsensitive) {
            attributedString[range].foregroundColor = UIColor(Color("AccentGold"))
            attributedString[range].font = .custom("Poppins-Bold", size: 16)
        }
        return attributedString
    }
}

// MARK: - Emoji Keyboard

private struct EmojiKeyboardField: UIViewRepresentable {
    @Binding var isPresented: Bool
    let onEmojiSelected: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEmojiSelected: onEmojiSelected, isPresented: $isPresented)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = EmojiTextField()
        field.delegate = context.coordinator
        field.textContentType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if isPresented && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isPresented && uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let onEmojiSelected: (String) -> Void
        @Binding var isPresented: Bool

        init(onEmojiSelected: @escaping (String) -> Void, isPresented: Binding<Bool>) {
            self.onEmojiSelected = onEmojiSelected
            self._isPresented = isPresented
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if !string.isEmpty && string.unicodeScalars.allSatisfy({ $0.properties.isEmoji && $0.properties.isEmojiPresentation }) {
                onEmojiSelected(string)
                textField.text = ""
                isPresented = false
                return false
            }
            return false
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isPresented = false
        }
    }
}

private class EmojiTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }

    override var textInputContextIdentifier: String? { "" }
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
