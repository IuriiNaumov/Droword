import SwiftUI
import PhotosUI

struct ScanWordsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @ObservedObject var store: WordsStore

    var initialText: String = ""

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

    private var duplicateWords: [ExtractedWord] {
        extractedWords.filter {
            alreadyInDictionary.contains($0.word.lowercased())
                && !addedWordIDs.contains($0.id)
                && !skippedWordIDs.contains($0.id)
        }
    }

    private var newWordsCountLine: String {
        let n = visibleWords.count
        return String(localized: "\(n) new words")
    }

    private var alreadyInDictionaryLine: String {
        let n = duplicateWords.count
        return String(localized: "\(n) words are already in the dictionary")
    }

    var body: some View {
        NavigationStack {
            Group {
                if isExtracting {
                    extractingSection
                } else if extractedWords.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Scan words")
                                .sheetTitle()
                                .accessibilityLabel(Text("Scan words from photo"))

                            photoSelectionSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                        .iPadContentWidth(600)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        resultsSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                            .iPadContentWidth(600)
                    }
                }
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
            .onAppear {
                let seed = initialText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !seed.isEmpty, extractedWords.isEmpty, !isExtracting else { return }
                pastedText = seed
                Task { await extractFromPastedText() }
            }
        }
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
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(themeStore.accentBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            Text("Take a photo of a word list, textbook page, or handout.")
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

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

            Text("Photos are sent to servers for scanning. Words are not stored on the server after scanning.")
                .font(themeStore.regular(13))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

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
        VStack(alignment: .leading, spacing: 16) {
            Text("New words")
                .sheetTitle()

            VStack(alignment: .leading, spacing: 6) {
                if visibleWords.count > 0 {
                    HStack(alignment: .firstTextBaseline) {
                        Text(newWordsCountLine)
                            .font(themeStore.regular(15))
                            .foregroundStyle(themeStore.secondaryText)

                        Spacer(minLength: 8)

                        if addedCount > 0 {
                            Text("\(addedCount) added")
                                .font(themeStore.regular(13))
                                .foregroundStyle(themeStore.accentGreen)
                        }
                    }
                }

                if !duplicateWords.isEmpty {
                    Text(alreadyInDictionaryLine)
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
            }

            if visibleWords.count > 1 {
                Button {
                    Haptics.lightImpact()
                    addAllWords()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add all")
                    }
                    .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
            }

            ForEach(visibleWords) { word in
                extractedWordCard(word)
                    .transition(.scale.combined(with: .opacity))
            }

            if !duplicateWords.isEmpty {
                Text("Already in dictionary")
                    .font(themeStore.medium(15))
                    .foregroundStyle(themeStore.secondaryText)
                    .padding(.top, visibleWords.isEmpty ? 0 : 4)

                ForEach(duplicateWords) { word in
                    duplicateWordCard(word)
                }
            }

            if visibleWords.isEmpty && addedCount > 0 {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(themeStore.accentBlue)

                    Text("All done!")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)

                    Text("\(addedCount) words added to your dictionary")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)

                    Button {
                        Haptics.lightImpact()
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(themeStore.medium(16))
                            .foregroundStyle(themeStore.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            Button {
                Haptics.lightImpact()
                resetState()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera")
                    Text("Scan another photo")
                }
                .font(themeStore.bold(17))
                .foregroundStyle(themeStore.accentBlue)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                        .fill(themeStore.mainAccentColor.opacity(0.12))
                )
            }
            .buttonStyle(Duo3DButtonStyle())
        }
    }

    private func extractedWordCard(_ word: ExtractedWord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word.word)
                .font(themeStore.medium(22))
                .foregroundStyle(themeStore.mainText)

            Text(word.translation)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.secondaryText)

            if let transcription = word.transcription, !transcription.isEmpty {
                Text("[\(transcription)]")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))
            }

            HStack {
                Button {
                    withAnimation(.spring()) {
                        addWord(word)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add")
                    }
                    .font(themeStore.medium(13))
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(themeStore.accentBlue)
                    .clipShape(Capsule())
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut) {
                        _ = skippedWordIDs.insert(word.id)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("Skip")
                    }
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.accentBlue)
                }
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.accentBlue.opacity(0.15) as Color)
        )
        .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
    }

    private func duplicateWordCard(_ word: ExtractedWord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.word)
                    .font(themeStore.medium(18))
                    .foregroundStyle(themeStore.secondaryText)
                Text(word.translation)
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.8))
            }
            Spacer(minLength: 0)
            Text("Added")
                .font(themeStore.bold(12))
                .foregroundStyle(themeStore.accentGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(themeStore.accentGreen.opacity(0.14))
                )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.cardBg)
        )
        .opacity(0.85)
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
        let hasTranslation = !(word.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        let newWord = StoredWord(
            word: word.word,
            type: word.type ?? "",
            translation: word.translation,
            example: nil,
            transcription: word.transcription,
            fromLanguage: languageStore.learningLanguage,
            toLanguage: languageStore.nativeLanguage,
            needsEnrichment: !hasTranslation
        )
        store.add(newWord)
        addedWordIDs.insert(word.id)
        addedCount += 1
        if !hasTranslation {
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
    ScanWordsView(store: WordsStore())
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
}
