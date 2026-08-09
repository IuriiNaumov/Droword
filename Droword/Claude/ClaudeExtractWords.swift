import Foundation
import UIKit

struct ExtractedWord: Identifiable, Codable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let type: String?
    let transcription: String?

    init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        type: String? = nil,
        transcription: String? = nil
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.type = type
        self.transcription = transcription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.word = try container.decode(String.self, forKey: .word)
        self.translation = try container.decode(String.self, forKey: .translation)
        self.type = try? container.decode(String.self, forKey: .type)
        self.transcription = try? container.decode(String.self, forKey: .transcription)
    }
}

struct ExtractedWordsResponse: Codable {
    let words: [ExtractedWord]
}

@MainActor
func extractWordsFromImage(
    image: UIImage,
    languageStore: LanguageStore
) async throws -> [ExtractedWord] {
    let resized = resizeImage(image, maxDimension: 1024)
    guard let jpegData = resized.jpegData(compressionQuality: 0.6) else {
        throw URLError(.cannotDecodeContentData)
    }
    let base64 = jpegData.base64EncodedString()

    let body: [String: Any] = [
        "image": base64,
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage
    ]

    var request = try APIClient.makeRequest(endpoint: "extract-words", body: body)
    request.timeoutInterval = 60
    let (data, response) = try await APIClient.perform(request)
    let validated = try APIClient.validateResponse(data, response)
    let result = try JSONDecoder().decode(ExtractedWordsResponse.self, from: validated)
    return result.words
}

private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
    let size = image.size
    guard max(size.width, size.height) > maxDimension else { return image }

    let scale: CGFloat
    if size.width > size.height {
        scale = maxDimension / size.width
    } else {
        scale = maxDimension / size.height
    }

    let newSize = CGSize(width: size.width * scale, height: size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
