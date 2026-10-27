import SwiftUI
import PhotosUI
import UIKit

struct ScanWordsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @ObservedObject var store: WordsStore

    var initialText: String = ""
    var initialImage: UIImage? = nil

    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    @State private var selectedImage: UIImage?
    @State private var pastedText: String = ""
    @State private var extractedWords: [ExtractedWord] = []
    @State private var addedWordIDs: Set<UUID> = []
    @State private var skippedWordIDs: Set<UUID> = []
    @State private var isExtracting = false
    @State private var errorMessage: String?
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var addedCount = 0
    @State private var showPremiumWall = false
    @State private var alreadyInDictionary: Set<String> = []
    @State private var extractSource: ExtractSource = .photo

    private enum ExtractSource { case photo, text }

    private var existingWordKeys: Set<String> {
        Set(store.words.map { $0.word.lowercased() })
    }

    private var visibleWords: [ExtractedWord] {
        extractedWords.filter {
            !addedWordIDs.contains($0.id)
                && !skippedWordIDs.contains($0.id)
                && !alreadyInDictionary.contains($0.word.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isExtracting {
                    extractingSection
                } else if extractedWords.isEmpty {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Scan words")
                                    .sheetTitle()
                                    .accessibilityLabel(Text("Scan words from photo"))

                                photoSelectionSection
                            }
                            .padding(.horizontal, DesignSpacing.screenInset)
                            .padding(.bottom, 12)
                            .iPadContentWidth(600)
                        }

                        Text("Photos are sent to servers for scanning. Words are not stored on the server after scanning.")
                            .font(themeStore.regular(11))
                            .foregroundStyle(themeStore.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSpacing.screenInset)
                            .padding(.bottom, 12)
                            .iPadContentWidth(600)
                    }
                } else if visibleWords.isEmpty && addedCount > 0 {
                    WordsAddedPage(count: addedCount) {
                        dismiss()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        resultsSection
                            .padding(.horizontal, DesignSpacing.screenInset)
                            .padding(.bottom, 20)
                            .iPadContentWidth(600)
                    }
                }
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !(visibleWords.isEmpty && addedCount > 0 && !extractedWords.isEmpty) {
                        CloseButton()
                    }
                }
            }
            .onAppear {
                guard extractedWords.isEmpty, !isExtracting else { return }
                if let initialImage {
                    selectedImage = initialImage
                    SharedScanInbox.clear()
                    Task { await extractWords() }
                    return
                }
                let seed = initialText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !seed.isEmpty else { return }
                pastedText = seed
                Task { await extractFromPastedText() }
            }
        }
        .environmentObject(store)
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                showCamera = false
                if let image {
                    selectedImage = image
                    Task { await extractWords() }
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    await extractWords()
                }
            }
        }
    }

    private var photoSelectionSection: some View {
        VStack(spacing: 20) {
            StickerIcon(art: .scan, size: 112)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            Text("Take a photo of a word list, textbook page, or handout.")
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: DesignSpacing.buttonGap) {
                Button {
                    Haptics.lightImpact()
                    startScan(camera: true)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera")
                        Text("Take a photo")
                    }
                    .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())

                Button {
                    Haptics.lightImpact()
                    startScan(camera: false)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from library")
                    }
                    .duo3DSecondaryStyle()
                }
                .buttonStyle(Duo3DButtonStyle())
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.accentRed)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }

    private var extractingSection: some View {
        VStack(spacing: 16) {
            LoadingStagesView(
                dotSize: 14,
                bounceHeight: 10,
                spacing: 10,
                color: themeStore.mainAccentColor
            )
            .frame(height: 34)

            Text(extractSource == .text
                 ? "Extracting words from text…"
                 : "Extracting words from photo…")
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Scan words")
                .sheetTitle()

            if !visibleWords.isEmpty {
                HStack {
                    Text("\(visibleWords.count) words")
                        .font(themeStore.bold(20))
                        .foregroundStyle(themeStore.mainText)

                    Spacer()

                    if addedCount > 0 {
                        Text("\(addedCount) added")
                            .font(themeStore.regular(13))
                            .foregroundStyle(themeStore.accentBlue)
                    }
                }

                if visibleWords.count > 1 {
                    Button {
                        Haptics.lightImpact()
                        addAllWords()
                    } label: {
                        HStack(spacing: 6) {
                            AddPlusIcon()
                            Text("Add all")
                        }
                        .duo3DStyle(themeStore.mainAccentColor)
                    }
                    .buttonStyle(Duo3DButtonStyle())
                }

                ForEach(visibleWords) { word in
                    SelectableWordCard(
                        word: word.word,
                        translation: word.translation,
                        type: word.type,
                        transcription: word.transcription,
                        example: word.example,
                        explanation: word.explanation,
                        breakdown: word.breakdown,
                        collocations: word.collocations,
                        synonyms: word.synonyms,
                        antonyms: word.antonyms,
                        forms: word.forms,
                        onAdd: { addWord(word) },
                        onSkip: { _ = skippedWordIDs.insert(word.id) }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            } else if skippedWordIDs.isEmpty {
                allAlreadySavedView
            }

            Button {
                Haptics.lightImpact()
                resetState()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera")
                    Text("Scan another photo")
                }
                .duo3DSecondaryStyle()
            }
            .buttonStyle(Duo3DButtonStyle())
        }
    }

    private var allAlreadySavedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(themeStore.accentBlue)

            Text("All done!")
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)

            Text("All words already in your dictionary")
                .font(themeStore.regular(14))
                .foregroundStyle(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func startScan(camera: Bool) {
        guard isPremium || DailyLimitsManager.canScanPhoto else {
            showPremiumWall = true
            return
        }
        if camera {
            showCamera = true
        } else {
            showPhotosPicker = true
        }
    }

    private func extractWords() async {
        guard !isExtracting, let image = selectedImage else { return }
        errorMessage = nil
        extractSource = .photo

        let canUse = isPremium || DailyLimitsManager.canScanPhoto
        guard canUse else {
            selectedImage = nil
            showPremiumWall = true
            return
        }

        isExtracting = true

        do {
            let words = try await extractWordsFromImage(image: image, languageStore: languageStore)

            if !isPremium {
                DailyLimitsManager.recordPhotoScan()
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                alreadyInDictionary = Set(
                    words
                        .map { $0.word.lowercased() }
                        .filter { existingWordKeys.contains($0) }
                )
                extractedWords = words
                isExtracting = false
            }

            if words.isEmpty {
                errorMessage = String(localized: "No words found in the image. Try a clearer photo.")
                resetState()
            } else if visibleWords.isEmpty {
                errorMessage = String(localized: "All of these words are already in your dictionary.")
            }
        } catch {
            #if DEBUG
            print("⚠️ Extract words error: \(error.localizedDescription)")
            #endif
            await MainActor.run {
                isExtracting = false
                errorMessage = String(localized: "Failed to extract words. Please try again.")
                selectedImage = nil
            }
        }
    }

    private func extractFromPastedText() async {
        let text = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isExtracting, !text.isEmpty else { return }
        errorMessage = nil
        extractSource = .text

        let canUse = isPremium || DailyLimitsManager.canScanPhoto
        guard canUse else {
            showPremiumWall = true
            return
        }

        isExtracting = true

        do {
            let words = try await extractWordsFromText(text: text, languageStore: languageStore)

            if !isPremium {
                DailyLimitsManager.recordPhotoScan()
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                alreadyInDictionary = Set(
                    words
                        .map { $0.word.lowercased() }
                        .filter { existingWordKeys.contains($0) }
                )
                extractedWords = words
                isExtracting = false
            }

            if words.isEmpty {
                errorMessage = String(localized: "No words found in that text. Try a longer excerpt.")
            } else if visibleWords.isEmpty {
                errorMessage = String(localized: "All of these words are already in your dictionary.")
            }
        } catch {
            #if DEBUG
            print("⚠️ Extract text error: \(error.localizedDescription)")
            #endif
            await MainActor.run {
                isExtracting = false
                errorMessage = String(localized: "Failed to extract words. Please try again.")
            }
        }
    }

    private func addWord(_ word: ExtractedWord) {
        let key = word.word.lowercased()
        guard !existingWordKeys.contains(key) else {
            alreadyInDictionary.insert(key)
            return
        }
        let newWord = word.asStoredWord(
            fromLanguage: languageStore.learningLanguage,
            toLanguage: languageStore.nativeLanguage
        )
        store.add(newWord)
        addedWordIDs.insert(word.id)
        addedCount += 1
        if newWord.needsEnrichment {
            NotificationCenter.default.post(name: .triggerEnrichment, object: nil)
        }
    }

    private func addAllWords() {
        for word in visibleWords {
            addWord(word)
        }
    }

    private func resetState() {
        selectedImage = nil
        pastedText = ""
        extractSource = .photo
        extractedWords = []
        addedWordIDs = []
        skippedWordIDs = []
        alreadyInDictionary = []
        isExtracting = false
        errorMessage = nil
        selectedPhotoItem = nil
    }
}

#Preview {
    let store = WordsStore()
    ScanWordsView(store: store)
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
        .environmentObject(store)
}
