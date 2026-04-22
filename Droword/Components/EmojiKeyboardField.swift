import SwiftUI
import UIKit

struct EmojiKeyboardField: UIViewRepresentable {
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

class EmojiTextField: UITextField {
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
