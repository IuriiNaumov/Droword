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
                    self?.openApp(with: Self.firstUsableToken(from: trimmed))
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
                if let host = url?.host, !host.isEmpty {
                    self?.openApp(with: host)
                } else if let absolute = url?.absoluteString, !absolute.isEmpty {
                    self?.openApp(with: absolute)
                } else {
                    self?.done()
                }
            }
        }
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

    private func openApp(with word: String) {
        guard !word.isEmpty,
              let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "droword://add?word=\(encoded)") else {
            done()
            return
        }

        if let defaults = UserDefaults(suiteName: "group.com.droword.shared") {
            defaults.set(word, forKey: "pendingSharedWord")
        }

        var responder: UIResponder? = self as UIResponder
        while let current = responder {
            let openURL = NSSelectorFromString("openURL:")
            if current.responds(to: openURL) {
                current.perform(openURL, with: url)
                break
            }
            responder = current.next
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.done()
        }
    }

    private func done() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
