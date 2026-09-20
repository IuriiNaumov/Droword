import SwiftUI

struct ChatSceneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject private var learningProfile = LearningProfileStore.shared
    @StateObject private var model: ChatSceneViewModel
    @FocusState private var inputFocused: Bool
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var showPremiumWall = false

    init(target: ChatSceneTarget) {
        _model = StateObject(wrappedValue: ChatSceneViewModel(target: target))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ChatSceneHeaderView(
                    word: model.target.word,
                    translation: model.target.translation,
                    userTurns: model.userTurns
                )
                if model.isOfflinePractice {
                    StatusBannerView(
                        icon: "wifi.slash",
                        iconColor: themeStore.accentGold,
                        title: "You're offline",
                        subtitle: "Chat scenes need a connection. Come back online to practice.",
                        useCard: true
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                messagesList
                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.accentRed)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if model.isDone {
                    ChatDoneBar(usedWord: model.usedWord) {
                        Haptics.buttonPress()
                        dismiss()
                    }
                } else {
                    ChatComposerBar(
                        draft: $model.draft,
                        canSend: model.canSend,
                        isFocused: $inputFocused,
                        onSend: { Task { await send() } }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
        }
        .task {
            await model.loadOpening(
                languageStore: languageStore,
                goal: learningProfile.goal.localizedTitle,
                isPremium: isPremium
            )
            if model.needsPremium {
                showPremiumWall = true
            } else {
                inputFocused = true
            }
        }
        .onChange(of: model.needsPremium) { _, needs in
            if needs { showPremiumWall = true }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.messages) { message in
                        ChatBubbleView(
                            message: message,
                            showHint: !model.isDone,
                            onHint: { hint in
                                model.useHint(hint)
                                inputFocused = true
                            }
                        )
                        .id(message.id)
                    }
                    if model.isSending {
                        ChatTypingRow()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .iPadContentWidth(600)
            }
            .onChange(of: model.messages.count) { _, _ in
                scrollToEnd(proxy)
            }
            .onChange(of: model.isSending) { _, sending in
                if sending { scrollToEnd(proxy) }
            }
        }
    }

    private func send() async {
        await model.send(
            store: store,
            languageStore: languageStore,
            goal: learningProfile.goal.localizedTitle,
            isPremium: isPremium
        )
        if model.isDone {
            inputFocused = false
        }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        if model.isSending {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        } else if let last = model.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    ChatSceneView(
        target: ChatSceneTarget(
            id: UUID(),
            word: "hola",
            translation: "hello",
            example: "¡Hola!"
        )
    )
    .environmentObject(WordsStore())
    .environmentObject(LanguageStore())
    .environmentObject(ThemeStore())
}
