import SwiftUI
import AVFoundation

@main
struct WoordyApp: App {
    @StateObject private var store = WordsStore()

    init() {
        warmUpKeyboard()
        warmUpAudioSession()
        warmUpGPT()
        preloadFonts()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
        }
    }

    private func warmUpKeyboard() {
        // Прогреваем подсистему клавиатуры (ускоряет первое появление TextField)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let textField = UITextField()
            UIApplication.shared.windows.first?.addSubview(textField)
            textField.becomeFirstResponder()
            textField.resignFirstResponder()
            textField.removeFromSuperview()
        }
    }

    private func warmUpAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback)
        try? session.setActive(true)
    }

    private func warmUpGPT() {
        Task.detached(priority: .background) {
            _ = try? await translateWithGPT(
                word: "hola",
                sourceLang: "Spanish",
                targetLang: "Russian"
            )
        }
    }

    private func preloadFonts() {
        _ = UIFont(name: "Poppins-Bold", size: 14)
        _ = UIFont(name: "Poppins-Regular", size: 14)
    }
}
