import SwiftUI
import UIKit

struct InstagramStoriesTemplateView: View {
    let word: StoredWord
    let themeStore: ThemeStore

    static func gradientTop(_ themeStore: ThemeStore) -> Color {
        switch themeStore.palette {
        case .colorful:   return Color(red: 0.29, green: 0.50, blue: 0.77)
        case .night:      return Color(red: 0.12, green: 0.10, blue: 0.20)
        case .ocean:      return Color(red: 0.07, green: 0.48, blue: 0.54)
        case .sunset:     return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .paper:      return Color(red: 0.77, green: 0.47, blue: 0.29)
        case .duolingo:   return Color(red: 0.27, green: 0.72, blue: 0.00)
        case .glass:      return Color(red: 0.0, green: 0.48, blue: 1.0)
        }
    }

    static func gradientBottom(_ themeStore: ThemeStore) -> Color {
        switch themeStore.palette {
        case .colorful:   return Color(red: 0.76, green: 0.37, blue: 0.51)
        case .night:      return Color(red: 0.65, green: 0.55, blue: 0.98)
        case .ocean:      return Color(red: 0.49, green: 0.88, blue: 0.84)
        case .sunset:     return Color(red: 1.0, green: 0.60, blue: 0.26)
        case .paper:      return Color(red: 0.90, green: 0.82, blue: 0.68)
        case .duolingo:   return Color(red: 0.10, green: 0.54, blue: 0.43)
        case .glass:      return Color(red: 0.69, green: 0.32, blue: 0.87)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Self.gradientTop(themeStore), Self.gradientBottom(themeStore)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)

                VStack(spacing: 4) {
                    Text("Droword")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Word of the day")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
                    .frame(height: 36)

                ShareWordCardView(
                    word: word,
                    backgroundColor: Color(.secondarySystemBackground),
                    cardWidth: 310
                )

                Spacer()

                Text("Learn vocabulary smarter")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 80)
            }
        }
        .frame(width: 360, height: 640)
    }
}

struct ShareStreakTemplateView: View {
    let streak: Int
    let word: StoredWord?
    let themeStore: ThemeStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [InstagramStoriesTemplateView.gradientTop(themeStore), InstagramStoriesTemplateView.gradientBottom(themeStore)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer().frame(height: 88)

                Text("Droword")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer().frame(height: 28)

                VStack(spacing: 8) {
                    Text("\(streak)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("day streak")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }

                if let word {
                    Spacer().frame(height: 36)
                    ShareWordCardView(
                        word: word,
                        backgroundColor: Color(.secondarySystemBackground),
                        cardWidth: 310
                    )
                }

                Spacer()

                Text("Still showing up.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 80)
            }
        }
        .frame(width: 360, height: 640)
    }
}

enum InstagramStoriesShare {

    static var isInstagramInstalled: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static func renderStoriesImage(for word: StoredWord, themeStore: ThemeStore) -> UIImage? {
        let view = InstagramStoriesTemplateView(word: word, themeStore: themeStore)

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
        case .night:
            topHex = "#1A1628"
            bottomHex = "#A78BFA"
        case .ocean:
            topHex = "#127A8A"
            bottomHex = "#7EE0D6"
        case .sunset:
            topHex = "#E8825C"
            bottomHex = "#F0A850"
        case .paper:
            topHex = "#C4784A"
            bottomHex = "#E4D2B8"
        case .duolingo:
            topHex = "#45B800"
            bottomHex = "#1A8A6E"
        case .glass:
            topHex = "#007AFF"
            bottomHex = "#AF52DE"
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
