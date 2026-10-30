import SwiftUI
import UIKit

struct InstagramStoriesTemplateView: View {
    let word: StoredWord
    @ObservedObject var themeStore: ThemeStore

    static func gradientTop(_ themeStore: ThemeStore) -> Color {
        ShareWordPosterView.gradientTop(themeStore)
    }

    static func gradientBottom(_ themeStore: ThemeStore) -> Color {
        ShareWordPosterView.gradientBottom(themeStore)
    }

    var body: some View {
        ShareWordPosterView(
            word: word,
            themeStore: themeStore,
            width: 360,
            height: 640,
            useThemeGradient: true,
            showsBrand: true
        )
        .environmentObject(themeStore)
    }
}


enum InstagramStoriesShare {

    static var isInstagramInstalled: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static func renderStoriesImage(for word: StoredWord, themeStore: ThemeStore) -> UIImage? {
        let view = InstagramStoriesTemplateView(word: word, themeStore: themeStore)
            .environmentObject(themeStore)

        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        controller.safeAreaRegions = SafeAreaRegions()

        let size = CGSize(width: 360, height: 640)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.insetsLayoutMarginsFromSafeArea = false
        controller.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    @discardableResult
    static func shareToInstagramStories(word: StoredWord, themeStore: ThemeStore) -> Bool {
        guard let image = renderStoriesImage(for: word, themeStore: themeStore),
              let imageData = image.pngData() else {
            return false
        }

        let topHex: String
        let bottomHex: String
        switch themeStore.palette {
        case .colorful:
            topHex = "#4A80C4"
            bottomHex = "#C25E82"
        case .duolingo:
            topHex = "#45B800"
            bottomHex = "#1A8A6E"
        case .pixel:
            topHex = "#D62828"
            bottomHex = "#0E1224"
        case .glass:
            topHex = "#007AFF"
            bottomHex = "#AF52DE"
        case .custom:
            topHex = themeStore.customAccentHex
            bottomHex = themeStore.customAccentHex
        }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData,
            "com.instagram.sharedSticker.backgroundTopColor": topHex,
            "com.instagram.sharedSticker.backgroundBottomColor": bottomHex
        ]

        UIPasteboard.general.setItems(
            [pasteboardItems],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        guard let url = URL(string: "instagram-stories://share?source_application=com.droword") else {
            return false
        }

        UIApplication.shared.open(url)
        return true
    }

}

#Preview("Word") {
    let theme = ThemeStore()
    return InstagramStoriesTemplateView(
        word: StoredWord(
            word: "hola",
            type: "interjection",
            translation: "hello",
            example: "¡Hola! ¿Cómo estás?",
            transcription: "ˈola",
            tag: "Travel",
            fromLanguage: "Español",
            toLanguage: "English",
            reaction: "🔥"
        ),
        themeStore: theme
    )
    .environmentObject(theme)
}

