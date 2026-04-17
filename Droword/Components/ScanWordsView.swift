import SwiftUI
import PhotosUI

struct ScanWordsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @ObservedObject var store: WordsStore

    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    @State private var selectedImage: UIImage?
    @State private var extractedWords: [ExtractedWord] = []
    @State private var addedWordIDs: Set<UUID> = []
    @State private var skippedWordIDs: Set<UUID> = []
    @State private var isExtracting = false
    @State private var errorMessage: String?
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var addedCount = 0

    private var visibleWords: [ExtractedWord] {
        extractedWords.filter { !addedWordIDs.contains($0.id) && !skippedWordIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Scan words")
                        .sheetTitle()

                    if extractedWords.isEmpty && !isExtracting {
                        photoSelectionSection
                    } else if isExtracting {
                        extractingSection
                    } else {
                        resultsSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .iPadContentWidth(600)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SettingsBackButton()
                        .environmentObject(themeStore)
                }
            }
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

    // MARK: - Photo Selection

    private var photoSelectionSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(themeStore.mainAccentColor)

                Text("Take a photo of a word list, textbook page, or handout")
                    .font(themeStore.regular(15))
                    .foregroundColor(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 32)

            Button {
                Haptics.lightImpact()
                showCamera = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Take a photo")
                }
                .duo3DStyle(themeStore.mainAccentColor)
            }
            .buttonStyle(Duo3DButtonStyle())

            Button {
                Haptics.lightImpact()
                showPhotosPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose from library")
                }
                .font(themeStore.bold(17))
                .foregroundColor(themeStore.mainAccentColor)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeStore.mainAccentColor.opacity(0.12))
                )
            }
            .buttonStyle(Duo3DButtonStyle())

            if let errorMessage {
                Text(errorMessage)
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.accentRed)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Extracting

    private var extractingSection: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(spacing: 16) {
                LoadingStagesView(
                    dotSize: 14,
                    bounceHeight: 10,
                    spacing: 10,
                    color: themeStore.mainAccentColor
                )
                .frame(height: 34)

                Text("Extracting words from photo…")
                    .font(themeStore.regular(15))
                    .foregroundColor(themeStore.secondaryText)
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack {
                Text("\(visibleWords.count) words found")
                    .font(themeStore.bold(16))
                    .foregroundColor(themeStore.mainText)

                Spacer()

                if addedCount > 0 {
                    Text("\(addedCount) added")
                        .font(themeStore.regular(13))
                        .foregroundColor(themeStore.accentGreen)
                }
            }

            if visibleWords.count > 1 {
                Button {
                    Haptics.lightImpact()
                    addAllWords()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
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

            if visibleWords.isEmpty && addedCount > 0 {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(themeStore.accentGreen)

                    Text("All done!")
                        .font(themeStore.bold(18))
                        .foregroundColor(themeStore.mainText)

                    Text("\(addedCount) words added to your dictionary")
                        .font(themeStore.regular(14))
                        .foregroundColor(themeStore.secondaryText)

                    Button {
                        Haptics.lightImpact()
                        dismiss()
                    } label: {
                        Text("Close")
                            .duo3DStyle(themeStore.mainAccentColor)
                    }
                    .buttonStyle(Duo3DButtonStyle())
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            // "Scan another" button when results are shown
            Button {
                Haptics.lightImpact()
                resetState()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                    Text("Scan another photo")
                }
                .font(themeStore.bold(17))
                .foregroundColor(themeStore.mainAccentColor)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeStore.mainAccentColor.opacity(0.12))
                )
            }
            .buttonStyle(Duo3DButtonStyle())
        }
    }

    private func extractedWordCard(_ word: ExtractedWord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word.word)
                .font(themeStore.bold(22))
                .foregroundColor(themeStore.mainText)

            Text(word.translation)
                .font(themeStore.regular(16))
                .foregroundColor(themeStore.secondaryText)

            if let transcription = word.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))
            }

            HStack {
                Button {
                    withAnimation(.spring()) {
                        addWord(word)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(themeStore.medium(13))
                    .foregroundColor(.white)
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
                    .foregroundColor(themeStore.accentBlue)
                }
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeStore.accentBlue.opacity(0.15) as Color)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Actions

    private func extractWords() async {
        guard !isExtracting, let image = selectedImage else { return }
        errorMessage = nil

        let canUse = isPremium || DailyLimitsManager.canScanPhoto
        guard canUse else {
            errorMessage = String(localized: "Daily scan limit reached. Upgrade to Pro for unlimited scans.")
            selectedImage = nil
            return
        }

        isExtracting = true

        do {
            let words = try await extractWordsFromImage(image: image, languageStore: languageStore)

            if !isPremium {
                DailyLimitsManager.recordPhotoScan()
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                extractedWords = words
                isExtracting = false
            }

            if words.isEmpty {
                errorMessage = String(localized: "No words found in the image. Try a clearer photo.")
                resetState()
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

    private func addWord(_ word: ExtractedWord) {
        let newWord = StoredWord(
            word: word.word,
            type: word.type ?? "",
            translation: word.translation,
            example: nil,
            transcription: word.transcription,
            fromLanguage: languageStore.learningLanguage,
            toLanguage: languageStore.nativeLanguage,
            needsEnrichment: true
        )
        store.add(newWord)
        addedWordIDs.insert(word.id)
        addedCount += 1
    }

    private func addAllWords() {
        for word in visibleWords {
            addWord(word)
        }
    }

    private func resetState() {
        selectedImage = nil
        extractedWords = []
        addedWordIDs = []
        skippedWordIDs = []
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
