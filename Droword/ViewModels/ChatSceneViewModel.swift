import Combine
import Foundation

@MainActor
final class ChatSceneViewModel: ObservableObject {
    let target: ChatSceneTarget

    @Published var messages: [SceneChatMessage] = []
    @Published var draft = ""
    @Published var isSending = false
    @Published var isDone = false
    @Published var usedWord = false
    @Published var errorMessage: String?

    init(target: ChatSceneTarget) {
        self.target = target
    }

    var userTurns: Int {
        messages.filter { $0.role == .user }.count
    }

    var canSend: Bool {
        SceneWordValidator.canSend(draft: draft, isSending: isSending, isDone: isDone)
    }

    func loadOpening(languageStore: LanguageStore, goal: String?) async {
        isSending = true
        errorMessage = nil
        do {
            let turn = try await ClaudeScene.nextTurn(
                word: target.word,
                translation: target.translation,
                languageStore: languageStore,
                goal: goal,
                messages: []
            )
            apply(turn, afterUser: false)
        } catch {
            apply(
                SceneOfflineCopy.opening(
                    word: target.word,
                    translation: target.translation,
                    nativeLanguage: languageStore.nativeLanguage
                ),
                afterUser: false
            )
        }
        isSending = false
    }

    func send(store: WordsStore, languageStore: LanguageStore, goal: String?) async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSend else { return }
        Haptics.softTap()
        let localUsed = SceneWordValidator.used(text, word: target.word)
        messages.append(SceneChatMessage(role: .user, text: text, usedWord: localUsed))
        draft = ""
        isSending = true
        errorMessage = nil
        StudyActivityStore.shared.recordStudy(seedingFrom: store.words)
        store.syncStreakToAppGroup()

        do {
            let turn = try await ClaudeScene.nextTurn(
                word: target.word,
                translation: target.translation,
                languageStore: languageStore,
                goal: goal,
                messages: messages
            )
            apply(turn, afterUser: true)
        } catch {
            apply(
                SceneOfflineCopy.reply(
                    word: target.word,
                    translation: target.translation,
                    userTurns: userTurns,
                    usedWord: localUsed,
                    nativeLanguage: languageStore.nativeLanguage
                ),
                afterUser: true
            )
        }
        isSending = false
        if isDone {
            Haptics.celebration()
        }
    }

    func useHint(_ hint: String) {
        Haptics.softTap()
        draft = hint
    }

    private func apply(_ turn: SceneTurn, afterUser: Bool) {
        if afterUser, let lastUser = messages.lastIndex(where: { $0.role == .user }) {
            messages[lastUser].usedWord = turn.usedWord || messages[lastUser].usedWord
            if messages[lastUser].usedWord {
                usedWord = true
                Haptics.success()
            }
        }
        let reply = turn.reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reply.isEmpty else {
            if turn.done { isDone = true }
            return
        }
        messages.append(
            SceneChatMessage(
                role: .assistant,
                text: reply,
                hint: turn.hint,
                nudge: turn.nudge
            )
        )
        if turn.usedWord { usedWord = true }
        if turn.done { isDone = true }
    }
}
