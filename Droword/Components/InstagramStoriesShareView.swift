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

struct ShareStreakTemplateView: View {
    let streak: Int
    let word: StoredWord?
    @ObservedObject var themeStore: ThemeStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    ShareWordPosterView.gradientTop(themeStore),
                    ShareWordPosterView.gradientBottom(themeStore)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                Text("Droword")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 88)

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(streak)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("day streak")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 28)

                if let word {
                    ShareWordCardView(
                        word: word,
                        themeStore: themeStore,
                        cardWidth: 310
                    )
                    .padding(.top, 36)
                }

                Spacer(minLength: 0)

                Text("Still showing up.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 80)
            }
            .padding(.leading, 16)
            .padding(.trailing, 34)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 360, height: 640, alignment: .topLeading)
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

    static func renderStreakImage(streak: Int, word: StoredWord?, themeStore: ThemeStore) -> UIImage? {
        let view = ShareStreakTemplateView(streak: streak, word: word, themeStore: themeStore)
            .environmentObject(themeStore)
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        controller.safeAreaRegions = SafeAreaRegions()
        let size = CGSize(width: 360, height: 640)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    static func shareStreak(streak: Int, word: StoredWord?, themeStore: ThemeStore) {
        guard let image = renderStreakImage(streak: streak, word: word, themeStore: themeStore) else { return }
        if isInstagramInstalled, let imageData = image.pngData() {
            let pasteboardItems: [String: Any] = [
                "com.instagram.sharedSticker.backgroundImage": imageData,
                "com.instagram.sharedSticker.backgroundTopColor": "#4A80C4",
                "com.instagram.sharedSticker.backgroundBottomColor": "#C25E82"
            ]
            UIPasteboard.general.setItems(
                [pasteboardItems],
                options: [.expirationDate: Date().addingTimeInterval(300)]
            )
            if let url = URL(string: "instagram-stories://share?source_application=com.droword") {
                UIApplication.shared.open(url)
                return
            }
        }
        let text = streak == 1
            ? String(localized: "1 day streak on Droword")
            : String(localized: "\(streak) day streak on Droword")
        let ac = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.keyWindow?.rootViewController {
            var top = root
            while let presented = top.presentedViewController { top = presented }
            if let popover = ac.popoverPresentationController {
                popover.sourceView = top.view
                popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            top.present(ac, animated: true)
        }
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

#Preview("Streak") {
    let theme = ThemeStore()
    return ShareStreakTemplateView(
        streak: 12,
        word: StoredWord(
            word: "hola",
            type: "interjection",
            translation: "hello",
            example: "¡Hola! ¿Cómo estás?",
            tag: "Travel",
            fromLanguage: "Español",
            toLanguage: "English",
            reaction: "🔥"
        ),
        themeStore: theme
    )
    .environmentObject(theme)
}
