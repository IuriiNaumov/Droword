import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractSharedText()
    }

    private func extractSharedText() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            done()
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let text = data as? String {
                                self?.openApp(with: text.trimmingCharacters(in: .whitespacesAndNewlines))
                            } else {
                                self?.done()
                            }
                        }
                    }
                    return
                }
            }
        }

        done()
    }

    private func openApp(with word: String) {
        guard !word.isEmpty,
              let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "droword://add?word=\(encoded)") else {
            done()
            return
        }

        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self
        while let r = responder {
            if r.responds(to: selector) {
                r.perform(selector, with: url)
                break
            }
            responder = r.next
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.done()
        }
    }

    private func done() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
