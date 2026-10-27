import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractSharedContent()
    }

    private func extractSharedContent() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            done()
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    loadImage(from: provider)
                    return
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    loadText(from: provider, type: UTType.plainText.identifier)
                    return
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    loadText(from: provider, type: UTType.text.identifier)
                    return
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    loadURL(from: provider)
                    return
                }
            }
        }

        done()
    }

    private func loadImage(from provider: NSItemProvider) {
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.openApp(withSharedImage: image)
                    } else {
                        self?.loadImageItem(from: provider)
                    }
                }
            }
            return
        }
        loadImageItem(from: provider)
    }

    private func loadImageItem(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, _ in
            if let image = Self.image(from: item) {
                DispatchQueue.main.async {
                    self?.openApp(withSharedImage: image)
                }
                return
            }
            self?.loadImageFile(from: provider)
        }
    }

    private func loadImageFile(from provider: NSItemProvider) {
        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, _ in
            var image: UIImage?
            if let url, let data = try? Data(contentsOf: url) {
                image = UIImage(data: data)
            }
            DispatchQueue.main.async {
                if let image {
                    self?.openApp(withSharedImage: image)
                } else {
                    self?.done()
                }
            }
        }
    }

    private static func image(from item: NSSecureCoding?) -> UIImage? {
        if let image = item as? UIImage {
            return image
        }
        if let url = item as? URL, let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        if let data = item as? Data {
            return UIImage(data: data)
        }
        return nil
    }

    private func loadText(from provider: NSItemProvider, type: String) {
        provider.loadItem(forTypeIdentifier: type, options: nil) { [weak self] data, _ in
            DispatchQueue.main.async {
                let text: String?
                if let string = data as? String {
                    text = string
                } else if let data = data as? Data {
                    text = String(data: data, encoding: .utf8)
                } else {
                    text = nil
                }

                if let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
                    self?.openApp(withSharedText: trimmed)
                } else {
                    self?.done()
                }
            }
        }
    }

    private func loadURL(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
            DispatchQueue.main.async {
                let url = (data as? URL) ?? (data as? NSURL) as URL?
                if let absolute = url?.absoluteString, !absolute.isEmpty {
                    self?.openApp(withSharedText: absolute)
                } else {
                    self?.done()
                }
            }
        }
    }

    private static func shouldExtractPassage(_ text: String) -> Bool {
        if text.count > 80 { return true }
        let lines = text.components(separatedBy: .newlines).filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if lines.count >= 2 { return true }
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count >= 6
    }

    private static func firstUsableToken(from text: String) -> String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? text

        if firstLine.count <= 80 {
            return firstLine
        }

        let token = firstLine
            .components(separatedBy: .whitespacesAndNewlines)
            .first { !$0.isEmpty } ?? String(firstLine.prefix(80))
        return token
    }

    private func openApp(withSharedImage image: UIImage) {
        guard saveSharedImage(image) else {
            done()
            return
        }
        let defaults = UserDefaults(suiteName: "group.com.droword.shared")
        defaults?.removeObject(forKey: "pendingSharedText")
        defaults?.removeObject(forKey: "pendingSharedWord")
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.droword.pendingSharedImage" as CFString),
            nil,
            nil,
            true
        )
        openApp(url: URL(string: "droword://scan"))
    }

    private static func clearSharedImage() {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.droword.shared"
        ) else { return }
        let url = container.appendingPathComponent("pendingSharedImage.jpg")
        try? FileManager.default.removeItem(at: url)
    }

    private func saveSharedImage(_ image: UIImage) -> Bool {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.droword.shared"
        ) else { return false }
        let url = container.appendingPathComponent("pendingSharedImage.jpg")
        guard let data = jpegData(from: image) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private func jpegData(from image: UIImage) -> Data? {
        let maxSide: CGFloat = 1600
        let size = image.size
        let longest = max(size.width, size.height)
        let rendered: UIImage
        if longest > maxSide, longest > 0 {
            let scale = maxSide / longest
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            rendered = image
        }
        return rendered.jpegData(compressionQuality: 0.8)
    }

    private func openApp(withSharedText text: String) {
        let defaults = UserDefaults(suiteName: "group.com.droword.shared")
        let extractPassage = Self.shouldExtractPassage(text)
        let deepLink: URL?

        if extractPassage {
            defaults?.set(text, forKey: "pendingSharedText")
            defaults?.removeObject(forKey: "pendingSharedWord")
            Self.clearSharedImage()
            deepLink = URL(string: "droword://extract")
        } else {
            let word = Self.firstUsableToken(from: text)
            defaults?.set(word, forKey: "pendingSharedWord")
            defaults?.removeObject(forKey: "pendingSharedText")
            Self.clearSharedImage()
            guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                done()
                return
            }
            deepLink = URL(string: "droword://add?word=\(encoded)")
        }

        openApp(url: deepLink)
    }

    private func openApp(url: URL?) {
        guard let url else {
            done()
            return
        }

        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                finishAfterOpen()
                return
            }
            responder = current.next
        }

        responder = self
        let selector = NSSelectorFromString("openURL:")
        while let current = responder {
            if current.responds(to: selector) {
                current.perform(selector, with: url)
                break
            }
            responder = current.next
        }
        finishAfterOpen()
    }

    private func finishAfterOpen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.done()
        }
    }

    private func done() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
