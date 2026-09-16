import Foundation
import UserNotifications

enum ChatSceneLaunch {
    static let pendingWordIdKey = "chatScene.pendingWordId"
    static let pendingWordKey = "chatScene.pendingWord"

    static func store(wordId: String?, word: String?) {
        let defaults = UserDefaults.standard
        defaults.set(wordId, forKey: pendingWordIdKey)
        defaults.set(word, forKey: pendingWordKey)
    }

    static func consumeNotification(_ notification: UNNotification) {
        let info = notification.request.content.userInfo
        let type = info["type"] as? String
        let isEvening = type == "eveningChat"
            || notification.request.identifier == "notif.evening.chat"
        guard isEvening else { return }
        store(wordId: info["wordId"] as? String, word: info["word"] as? String)
        NotificationCenter.default.post(name: .openChatScene, object: nil, userInfo: info)
    }

    static func takePending() -> (wordId: String?, word: String?)? {
        let defaults = UserDefaults.standard
        let wordId = defaults.string(forKey: pendingWordIdKey)
        let word = defaults.string(forKey: pendingWordKey)
        guard wordId != nil || (word?.isEmpty == false) else { return nil }
        defaults.removeObject(forKey: pendingWordIdKey)
        defaults.removeObject(forKey: pendingWordKey)
        return (wordId, word)
    }
}
