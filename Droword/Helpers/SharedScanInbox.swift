import UIKit

enum SharedScanInbox {
    static let fileName = "pendingSharedImage.jpg"

    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    static var hasPending: Bool {
        guard let url = fileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    static func peekImage() -> UIImage? {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    static func takeImage() -> UIImage? {
        guard let image = peekImage() else { return nil }
        clear()
        return image
    }

    static func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static let readyName = "com.droword.pendingSharedImage"

    static func startListening() {
        guard !listening else { return }
        listening = true
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async {
                    SplashGate.skip = true
                    SplashGate.pendingScan = true
                    NotificationCenter.default.post(name: .skipSplash, object: nil)
                    NotificationCenter.default.post(name: .openScan, object: nil)
                }
            },
            readyName as CFString,
            nil,
            .deliverImmediately
        )
    }

    private static var listening = false
}
