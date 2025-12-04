import SwiftUI
import AVFoundation

struct WordCard: Identifiable {
    let id = UUID()
    let word: String
    let partOfSpeech: String
    let example: String
    let translation: String
    let tag: String?
}

struct PracticeView: View {
    @EnvironmentObject private var store: WordsStore

    @State private var currentIndex: Int = 0

    private var cards: [WordCard] {
        store.words.map { word in
            WordCard(
                word: word.word,
                partOfSpeech: word.type.isEmpty ? "word" : word.type,
                example: word.example ?? "Add an example later",
                translation: word.translation ?? "No translation yet",
                tag: word.tag
            )
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if cards.isEmpty {
                emptyState
            } else {
                VStack(spacing: 24) {
                    header
                    Spacer()

                    ZStack {
                        if currentIndex < cards.count {
                            WordCardPracticeView(
                                card: cards[currentIndex],
                                onForgot: showNextCard,
                                onKnew: showNextCard
                            )
                            .id(cards[currentIndex].id)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .animation(.spring(response: 0.35, dampingFraction: 0.8),
                                       value: currentIndex)
                        } else {
                            completionScreen
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Review")
                .font(.custom("Poppins-Bold", size: 38))

            Text("No words to practice yet")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)

            Text("Add some words to your dictionary and they will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.4))
                .padding(.top, 8)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Review")
                .font(.custom("Poppins-Bold", size: 38))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var completionScreen: some View {
        VStack(spacing: 12) {
            Text("You're done for now ✨")
                .font(.title2.bold())
            Text("You’ve reviewed all words for this session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func showNextCard() {
        currentIndex += 1
    }
}

struct WordCardPracticeView: View {
    let card: WordCard
    @State private var isRevealed = false

    let onForgot: () -> Void
    let onKnew: () -> Void

    private var backgroundColor: Color {
        switch card.tag {
        case "Chat":   return Color(.accentBlue)
        case "Travel": return Color(.accentGreen)
        case "Street": return Color(.accentPink)
        case "Movies": return Color(.accentPurple)
        case "Golden": return Color(.accentGold)
        default:       return Color(.defaultCard)
        }
    }

    private var clozeExample: String {
        let placeholder = "_____"
        let example = card.example
        guard !example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return placeholder }

        let target = card.word.lowercased()
        let punct = CharacterSet.punctuationCharacters
        var replaced = false

        let tokens = example.split(separator: " ")

        let processed = tokens.map { token -> String in
            var core = String(token)
            var trailing = ""

            while let last = core.unicodeScalars.last, punct.contains(last) {
                trailing.insert(Character(last), at: trailing.startIndex)
                core = String(core.unicodeScalars.dropLast())
            }

            if core.lowercased() == target {
                replaced = true
                return placeholder + trailing
            }

            return String(token)
        }

        return replaced ? processed.joined(separator: " ")
                        : "\(placeholder) \(example)"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24).fill(backgroundColor)
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor.opacity(0.85))
                .padding(6)

            VStack(spacing: 16) {
                Spacer(minLength: 12)

                Group {
                    if isRevealed {
                        Text(card.word)
                            .font(.custom("Poppins-Bold", size: 38))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(clozeExample)
                            .font(.custom("Poppins-SemiBold", size: 24))
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

                Text(card.partOfSpeech.uppercased())
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.mainBlack.opacity(0.7))

                if isRevealed {
                    Text(card.example)
                        .font(.custom("Poppins-Regular", size: 18))
                        .padding(.horizontal, 16)
                }

                Text(card.translation)
                    .font(.custom("Poppins-Regular", size: 18))
                    .padding(.horizontal, 16)

                Text(isRevealed ? "Tap to hide the answer" : "Tap to reveal the missing word")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.mainBlack.opacity(0.45))

                Spacer(minLength: 12)

                HStack(spacing: 12) {
                    Button {
                        isRevealed = false
                        onForgot()
                    } label: {
                        Text("I forgot")
                            .font(.custom("Poppins-Bold", size: 14))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.iDontKnowButton)
                            .foregroundColor(darkerShade(of: Color(.red), by: 0.28))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        isRevealed = false
                        onKnew()
                    } label: {
                        Text("I knew this")
                            .font(.custom("Poppins-Bold", size: 14))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.iKnowButton)
                            .foregroundColor(darkerShade(of: Color(.green), by: 0.28))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
            }
            .padding(22)
        }
        .frame(maxWidth: 520, maxHeight: 440)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isRevealed.toggle()
            }
        }
    }
}
    
    #Preview {
        let store = WordsStore()
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
        
        return PracticeView()
            .environmentObject(store)
    }

