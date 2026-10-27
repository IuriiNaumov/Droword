import Foundation
import UIKit

struct ExtractedWord: Identifiable, Codable, Equatable {
    let id: UUID
    let word: String
    let translation: String
    let type: String?
    let example: String?
    let explanation: String?
    let breakdown: String?
    let transcription: String?
    let collocations: [String]
    let synonyms: [String]
    let antonyms: [String]
    let mnemonic: String?
    let forms: [String]

    init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        type: String? = nil,
        example: String? = nil,
        explanation: String? = nil,
        breakdown: String? = nil,
        transcription: String? = nil,
        collocations: [String] = [],
        synonyms: [String] = [],
        antonyms: [String] = [],
        mnemonic: String? = nil,
        forms: [String] = []
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.type = type
        self.example = example
        self.explanation = explanation
        self.breakdown = breakdown
        self.transcription = transcription
        self.collocations = collocations
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.mnemonic = mnemonic
        self.forms = forms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.word = try container.decode(String.self, forKey: .word)
        self.translation = (try? container.decode(String.self, forKey: .translation)) ?? ""
        self.type = try? container.decode(String.self, forKey: .type)
        self.example = try? container.decode(String.self, forKey: .example)
        self.explanation = try? container.decode(String.self, forKey: .explanation)
        self.breakdown = try? container.decode(String.self, forKey: .breakdown)
        self.transcription = try? container.decode(String.self, forKey: .transcription)
        self.collocations = (try? container.decode([String].self, forKey: .collocations)) ?? []
        self.synonyms = (try? container.decode([String].self, forKey: .synonyms)) ?? []
        self.antonyms = (try? container.decode([String].self, forKey: .antonyms)) ?? []
        self.mnemonic = try? container.decode(String.self, forKey: .mnemonic)
        self.forms = (try? container.decode([String].self, forKey: .forms)) ?? []
    }

    func asStoredWord(fromLanguage: String, toLanguage: String) -> StoredWord {
        let primary = example
        let hasTranslation = !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let complete = hasTranslation && !(primary ?? "").isEmpty && !(explanation ?? "").isEmpty
        return StoredWord(
            word: word,
            type: type ?? "",
            translation: translation,
            example: primary,
            explanation: explanation,
            breakdown: breakdown,
            transcription: transcription,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage,
            needsEnrichment: !complete,
            examples: primary.map { [$0] } ?? [],
            collocations: collocations,
            synonyms: synonyms,
            antonyms: antonyms,
            mnemonic: mnemonic,
            forms: forms,
            formsResolved: !forms.isEmpty
        )
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
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]

    return try await performExtractWords(body: body)
}

@MainActor
func extractWordsFromText(
    text: String,
    languageStore: LanguageStore
) async throws -> [ExtractedWord] {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    let body: [String: Any] = [
        "text": String(trimmed.prefix(12000)),
        "learningLanguage": languageStore.learningLanguage,
        "nativeLanguage": languageStore.nativeLanguage,
        "level": languageStore.learningLevel
    ]

    return try await performExtractWords(body: body)
}

@MainActor
private func performExtractWords(body: [String: Any]) async throws -> [ExtractedWord] {
    var request = try APIClient.makeRequest(endpoint: "extract-words", body: body)
    request.timeoutInterval = 90
    let (data, response) = try await APIClient.perform(request)
    let validated = try APIClient.validateResponse(data, response)
    let result = try JSONDecoder().decode(ExtractedWordsResponse.self, from: validated)
    return result.words.map { word in
        ExtractedWord(
            id: word.id,
            word: word.word,
            translation: word.translation,
            type: word.type,
            example: word.example,
            explanation: word.explanation,
            breakdown: word.breakdown,
            transcription: word.transcription,
            collocations: word.collocations,
            synonyms: word.synonyms,
            antonyms: word.antonyms,
            mnemonic: word.mnemonic,
            forms: HighlightedExample.relevantForms(
                word.forms,
                headword: word.word,
                texts: [word.example ?? ""] + word.collocations
            )
        )
    }
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
