import SwiftUI

struct WordCardView: View, Equatable {
    let word: String
    let translation: String?
    let type: String?
    let example: String?
    let comment: String?
    let tag: String?
    let onDelete: () -> Void

    // Для Equatable
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

    private var backgroundColor: Color {
        switch tag {
        case "Social": return Color(red: 0.95, green: 0.80, blue: 1.00)
        case "Chat": return Color(red: 0.80, green: 0.90, blue: 1.00)
        case "Apps": return Color(red: 0.85, green: 1.00, blue: 0.85)
        case "Street": return Color(red: 1.00, green: 0.90, blue: 0.75)
        case "Travel": return Color(red: 1.00, green: 0.95, blue: 0.75)
        case "Movies": return Color(red: 1.00, green: 0.80, blue: 0.80)
        case "Work": return Color(red: 0.88, green: 0.88, blue: 0.95)
        default: return Color(.systemGray6)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isExpanded {
                if let tag = tag {
                    Text(tag)
                        .font(.custom("Poppins-Medium", size: 14))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(word)
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: playAudio) {
                        SoundWavesView(isPlaying: isPlaying)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }

                if let type = type {
                    Text(type)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.gray)
                }

                if let translation = translation {
                    Text(translation)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.black.opacity(0.9))
                }

                if let _ = example {
                    Text(highlightedExample)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.black.opacity(0.9))
                }

                if let comment = comment, !comment.isEmpty {
                    Text(comment)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.gray)
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
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: playAudio) {
                            SoundWavesView(isPlaying: isPlaying)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }

                    if let translation = translation {
                        Text(translation)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.black.opacity(0.9))
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
        .shadow(color: .black.opacity(isExpanded ? 0.15 : 0.05),
                radius: isExpanded ? 12 : 4,
                x: 0, y: isExpanded ? 6 : 2)
        .animation(.interpolatingSpring(stiffness: 100, damping: 12), value: isExpanded)
        .onTapGesture {
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
                isExpanded.toggle()
            }
        }
        .padding(.top, 12)
        .onAppear {
            if let example = example {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word)
            } else {
                highlightedExample = ""
            }
        }
        .onChange(of: example) { newValue in
            if let example = newValue {
                highlightedExample = Self.makeHighlightedExample(comment: example, word: word)
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

    private static func makeHighlightedExample(comment: String, word: String) -> AttributedString {
        var attributedString = AttributedString(comment)
        if let range = attributedString.range(of: word, options: .caseInsensitive) {
            attributedString[range].foregroundColor = .orange
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
            tag: "Social",
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
