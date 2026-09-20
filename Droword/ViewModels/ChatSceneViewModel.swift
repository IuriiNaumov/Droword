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
    @Published var needsPremium = false
    @Published var isOfflinePractice = false

    private var didRecordSceneUsage = false

    init(target: ChatSceneTarget) {
        self.target = target
    }

    var userTurns: Int {
        messages.filter { $0.role == .user }.count
    }

    var canSend: Bool {
        NetworkMonitor.shared.isConnected
            && !isOfflinePractice
            && SceneWordValidator.canSend(draft: draft, isSending: isSending, isDone: isDone)
    }

    func loadOpening(languageStore: LanguageStore, goal: String?, isPremium: Bool) async {
        isSending = true
        errorMessage = nil
        needsPremium = false

        guard NetworkMonitor.shared.isConnected else {
            isOfflinePractice = true
            isSending = false
            return
        }

        guard allowNetworkTurn(isPremium: isPremium) else {
            isSending = false
            return
        }

        do {
            let turn = try await ClaudeScene.nextTurn(
                word: target.word,
                translation: target.translation,
                languageStore: languageStore,
                goal: goal,
                messages: []
            )
            apply(turn, afterUser: false)
            recordSceneIfNeeded(isPremium: isPremium)
        } catch {
            if !NetworkMonitor.shared.isConnected {
                isOfflinePractice = true
            } else {
                errorMessage = String(localized: "Couldn't start the scene. Try again.")
            }
        }
        isSending = false
    }

    func send(store: WordsStore, languageStore: LanguageStore, goal: String?, isPremium: Bool) async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSend else { return }

        guard NetworkMonitor.shared.isConnected else {
            isOfflinePractice = true
            return
        }

        guard allowNetworkTurn(isPremium: isPremium) else { return }

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
            recordSceneIfNeeded(isPremium: isPremium)
        } catch {
            if !NetworkMonitor.shared.isConnected {
                isOfflinePractice = true
            } else {
                errorMessage = String(localized: "Couldn't send. Try again.")
            }
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

    private func allowNetworkTurn(isPremium: Bool) -> Bool {
        if didRecordSceneUsage || isPremium { return true }
        guard DailyLimitsManager.canStartScene else {
            needsPremium = true
            errorMessage = String(localized: "You've used today's free chat scenes. Upgrade to PRO for unlimited.")
            return false
        }
        return true
    }

    private func recordSceneIfNeeded(isPremium: Bool) {
        guard !didRecordSceneUsage else { return }
        didRecordSceneUsage = true
        if !isPremium {
            DailyLimitsManager.recordScene()
        }
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
