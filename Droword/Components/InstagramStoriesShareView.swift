import SwiftUI
import UIKit

// MARK: - Stories Template (360×640pt → 1080×1920px at @3x)

struct InstagramStoriesTemplateView: View {
    let word: StoredWord
    let themeStore: ThemeStore

    private var gradientTop: Color {
        switch themeStore.palette {
        case .colorful:   return Color(red: 0.29, green: 0.50, blue: 0.77)
        case .duolingo:   return Color(red: 0.27, green: 0.72, blue: 0.00)
        case .sunset:     return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .glass:      return Color(red: 0.0, green: 0.48, blue: 1.0)
        }
    }

    private var gradientBottom: Color {
        switch themeStore.palette {
        case .colorful:   return Color(red: 0.76, green: 0.37, blue: 0.51)
        case .duolingo:   return Color(red: 0.10, green: 0.54, blue: 0.43)
        case .sunset:     return Color(red: 1.0, green: 0.60, blue: 0.26)
        case .glass:      return Color(red: 0.69, green: 0.32, blue: 0.87)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [gradientTop, gradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)

                VStack(spacing: 4) {
                    Text("Droword")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundStyle(.white)
                    Text("Word of the day")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
                    .frame(height: 36)

                ShareWordCardView(
                    word: word,
                    backgroundColor: Color(.secondarySystemBackground),
                    cardWidth: 310
                )
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)

                Spacer()

                Text("Learn vocabulary smarter")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 80)
            }
        }
        .frame(width: 360, height: 640)
    }
}

// MARK: - Instagram Stories Sharing

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
        case .duolingo:
            topHex = "#45B800"
            bottomHex = "#1A8A6E"
        case .sunset:
            topHex = "#E8825C"
            bottomHex = "#F0A850"
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
}
