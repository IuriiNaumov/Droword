import SwiftUI
import AVFoundation

struct WordCardView: View, Equatable {
    let word: String
    let translation: String?
    let type: String?
    let example: String?
    let comment: String?
    let tag: String?
    let onDelete: () -> Void

    static func == (lhs: WordCardView, rhs: WordCardView) -> Bool {
        lhs.word == rhs.word &&
        lhs.translation == rhs.translation &&
        lhs.type == rhs.type &&
        lhs.example == rhs.example &&
        lhs.comment == rhs.comment &&
        lhs.tag == rhs.tag
    }

    @State private var isExpanded = true
    @State private var isPlaying = false
    @State private var highlightedExample: AttributedString = ""

    private static let gold = Color(hexRGB: 0xFFC107)
    private static let darkGold = Color(hexRGB: 0xE0A600)
    private static let deepTextGold = Color(hexRGB: 0x7B4B00)
    private static let midTextGold = Color(hexRGB: 0x966000)

    private var isGolden: Bool { tag == "Golden" }

    private var backgroundColor: Color {
        switch tag {
        case "Social": return Color(.accentYellow)
        case "Chat":   return Color(.accentBlue)
        case "Apps":   return Color(.accentGreen)
        case "Street": return Color(.accentPink)
        case "Movies": return Color(.accentPurple)
        case "Travel": return Color(.accentYellow)
        case "Work":   return Color(.accentMint)
        case "Golden": return Color(.accentGold)
        default:       return Color(.defaultCard)
        }
    }

    private var textColor: Color {
        Color(.black)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isExpanded {
                if let tag = tag {
                    Text(tag)
                        .font(.custom("Poppins-Medium", size: 14))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 4)
                        .background(isGolden ? Color.white.opacity(0.35) : Color(.mainGrey).opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundColor(.black)
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(word)
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(textColor)

                    Spacer()
                    Button(action: playAudio) {
                        SoundWavesView(isPlaying: isPlaying)
                            .frame(width: 24, height: 24)
                            .tint(.black)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }

                if let type = type {
                    Text(type)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(isGolden ? Self.midTextGold.opacity(0.8) : Color(.mainGrey))
                }

                if let translation = translation {
                    Text(translation)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(textColor)
                }

                if let _ = example {
                    Text(highlightedExample)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(textColor)
                }

                if let comment = comment, !comment.isEmpty {
                    Text(comment)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(isGolden ? Self.midTextGold.opacity(0.9) : Color(.mainGrey))
                        .padding(.top, 4)
                }

                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .padding(.trailing, 2)
                            .padding(.top, 8)
                    }
                    .buttonStyle(.plain)
                }

            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(word)
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: playAudio) {
                            SoundWavesView(isPlaying: isPlaying)
                                .frame(width: 24, height: 24)
                                .tint(.black)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }

                    if let translation = translation {
                        Text(translation)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                    }

                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .padding(.trailing, 2)
                                .padding(.top, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(16)
        .scaleEffect(isExpanded ? 1.02 : 0.98)
        .animation(.interpolatingSpring(stiffness: 100, damping: 12), value: isExpanded)
        .onTapGesture {
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
                isExpanded.toggle()
            }
        }
        .padding(.top, 12)
        .onAppear {
            if let example = example {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word, isGolden: isGolden)
            } else {
                highlightedExample = ""
            }
        }
        .onChange(of: example) { newValue in
            if let example = newValue {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word, isGolden: isGolden)
            } else {
                highlightedExample = ""
            }
        }
    }

    private func playAudio() {
        Task {
            isPlaying = true
            await AudioManager.shared.play(word: word)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation { isPlaying = false }
        }
    }

    private static func makeHighlightedExample(comment: String, word: String, isGolden: Bool) -> AttributedString {
        var attributedString = AttributedString(comment)
        if let range = attributedString.range(of: word, options: .caseInsensitive) {
            attributedString[range].foregroundColor = isGolden ? .accentColor : .orange
            attributedString[range].font = .custom("Poppins-Bold", size: 16)
        }
        return attributedString
    }
}

#Preview {
    VStack(spacing: 20) {
        WordCardView(
            word: "Sabroso",
            translation: "Вкусный",
            type: "adjective",
            example: "Este plato es muy sabroso y delicioso.",
            comment: "Мое любимое слово!",
            tag: "Golden",
            onDelete: {}
        )
        WordCardView(
            word: "Chido",
            translation: "Круто",
            type: "adjective",
            example: "La fiesta estuvo chido y divertida.",
            comment: nil,
            tag: "Slang",
            onDelete: {}
        )
    }
    .padding()
}
