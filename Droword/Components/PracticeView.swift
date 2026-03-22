import SwiftUI
import AVFoundation
import UIKit

struct WordCard: Identifiable {
    let id: UUID
    let word: String
    let partOfSpeech: String
    let example: String
    let translation: String
    let explanation: String?
    let breakdown: String?
    let transcription: String?
    let tag: String?
    let fromLanguage: String?
    let toLanguage: String?
    let comment: String?
}

enum PracticeMode: String, CaseIterable {
    case practice = "Practice"
    case listening = "Listening"
}

enum QuizDirection: String, CaseIterable {
    case normal = "Word → Translation"
    case reversed = "Translation → Word"
    case mixed = "Mixed"
}

struct PracticeView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var selectedMode: PracticeMode = .practice
    @State private var showListeningPlayer = false
    @State private var showPremiumWall = false
    @AppStorage("isPremium") private var isPremium: Bool = false

    private var hasEnoughWordsForPractice: Bool {
        store.words.filter { $0.translation != nil && !$0.translation!.isEmpty }.count >= 4
    }

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.bottom, 8)

                Group {
                    switch selectedMode {
                    case .practice:
                        if !hasEnoughWordsForPractice {
                            practiceEmptyState
                        } else {
                            QuizMixedView(sessionSize: 15, filterTag: nil, direction: .mixed)
                        }
                    case .listening:
                        listeningEntryView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .iPadContentWidth()
        }
        .fullScreenCover(isPresented: $showListeningPlayer) {
            ListeningPlayerView()
                .environmentObject(store)
                .environmentObject(themeStore)
                .environmentObject(languageStore)
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private var practiceEmptyState: some View {
        PracticeEmptyContent(
            icon: "rectangle.stack.badge.plus",
            title: "Not enough words yet",
            subtitle: "Add at least 4 words with translations to start practicing.",
            tip: "Tip: grab words from movies, chats, or walks — learning feels alive that way."
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice")
                .font(.custom("Poppins-Bold", size: 38))
                .foregroundColor(themeStore.mainText)

            modePicker
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(PracticeMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                    Haptics.selection()
                } label: {
                    Text(mode.rawValue)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(selectedMode == mode ? .white : themeStore.mainText)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedMode == mode ? themeStore.buttonAccent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }

    private var listeningEntryView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "headphones")
                .font(.system(size: 56))
                .foregroundColor(themeStore.mainText.opacity(0.25))

            VStack(spacing: 8) {
                Text("Audio flashcards")
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(themeStore.mainText)

                Text("Listen to words with pauses for active recall. Put on headphones and learn while doing other things.")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                Haptics.mediumImpact()
                if isPremium || DailyLimitsManager.canPlayTTS {
                    showListeningPlayer = true
                } else {
                    showPremiumWall = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("Open player")
                        .font(.custom("Poppins-Bold", size: 16))
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(store.words.isEmpty ? themeStore.secondaryText.opacity(0.3) : themeStore.buttonAccent)
                )
            }
            .buttonStyle(.plain)
            .disabled(store.words.isEmpty)

            if store.words.isEmpty {
                Text("Add some words first")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(themeStore.secondaryText.opacity(0.7))
                    .padding(.top, 6)
            }

            Spacer()
            Spacer()
        }
    }
}



#Preview {
    let store = WordsStore()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        store.clear()
        store.add(
            StoredWord(
                word: "No puedo creer lo que está pasando aquí",
                type: "adjective",
                translation: "Вкусный",
                example: "Este plato es muy sabroso y delicioso.",
                comment: "Моё любимое слово!",
                tag: "Golden",
                fromLanguage: "es",
                toLanguage: "ru"
            )
        )
        store.add(
            StoredWord(
                word: "chido",
                type: "adjective",
                translation: "Круто",
                example: "La fiesta estuvo chido y muy divertida.",
                comment: nil,
                tag: "Chat",
                fromLanguage: "es",
                toLanguage: "ru"
            )
        )
        store.add(
            StoredWord(
                word: "食べ物",
                type: "noun",
                translation: "Еда",
                example: "この食べ物はとてもおいしいです。",
                comment: nil,
                tag: "Travel",
                fromLanguage: "ja",
                toLanguage: "ru"
            )
        )
    }
    return PracticeView()
        .environmentObject(store)
        .environmentObject(LanguageStore())
}
