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
                    if !hasEnoughWordsForPractice {
                        practiceEmptyState
                    } else {
                        QuizMixedView(sessionSize: 15, filterTag: nil, direction: .mixed)
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
        HStack {
            Text("Practice")
                .font(.custom("Poppins-Bold", size: 38))
                .foregroundColor(themeStore.mainText)

            Spacer()

            Button {
                Haptics.mediumImpact()
                if isPremium || DailyLimitsManager.canPlayTTS {
                    showListeningPlayer = true
                } else {
                    showPremiumWall = true
                }
            } label: {
                Image(systemName: "headphones")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeStore.mainText)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(themeStore.cardBg)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
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
