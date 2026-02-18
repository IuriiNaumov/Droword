import SwiftUI
import AVFoundation

struct WordCardView: View, Equatable {
    let word: String
    let translation: String?
    let type: String?
    let example: String?
    let comment: String?
    let explanation: String?
    let breakdown: String?
    let tag: String?
    let onDelete: () -> Void

    static func == (lhs: WordCardView, rhs: WordCardView) -> Bool {
        lhs.word == rhs.word &&
        lhs.translation == rhs.translation &&
        lhs.type == rhs.type &&
        lhs.example == rhs.example &&
        lhs.explanation == rhs.explanation &&
        lhs.breakdown == rhs.breakdown &&
        lhs.comment == rhs.comment &&
        lhs.tag == rhs.tag
    }
    
    private func colorForTag(_ tag: String) -> Color {
        switch tag {
        case "Chat": return Color(.accentBlue)
        case "Travel": return Color(.accentGreen)
        case "Street": return Color(.accentPink)
        case "Movies": return Color(.accentPurple)
        case "Golden": return Color(.accentGold)
        default:
            if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }),
               let color = Color(fromHexString: custom.colorHex) {
                return color
            }
            return Color(.defaultCard)
        }
    }
    
    private struct TagBadge: View {
        let text: String
        var body: some View {
            Text(text)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.mainBlack)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @State private var isExpanded = true
    @State private var isPlaying = false
    @State private var highlightedExample: AttributedString = ""

    private var isGolden: Bool { tag == "Golden" }

    private var backgroundColor: Color {
        if let tag = tag, !tag.isEmpty {
            return colorForTag(tag)
        }
        return Color(.defaultCard)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            if isExpanded {
                
                if let tag = tag, !tag.isEmpty {
                    Text(tag)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(darkerShade(of: colorForTag(tag), by: 0.4))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(darkerShade(of: colorForTag(tag), by: 0.1), lineWidth: 1)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorForTag(tag))
                        )
                        .padding(.bottom, 2)
                }
                
                headerRow
                
                if let type = type, !type.isEmpty {
                    Text(type.capitalized)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)
                        .padding(.bottom, 2)
                }

                if let translation = translation {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(translation)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.mainBlack)
                    }
                }

                if let _ = example {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(highlightedExample)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.mainBlack)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if let explanation = explanation {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(explanation)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.mainBlack)
                    }
                }

                if let breakdown = breakdown {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(breakdown)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.mainBlack)
                    }
                }

                if let comment = comment, !comment.isEmpty {
                    Text(comment)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(Color(.mainGrey))
                        .padding(.top, 4)
                }
                

                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    .buttonStyle(.plain)
                }

            } else {

                headerRow

                if let translation = translation {
                    Text(translation)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.mainBlack)
                }

                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(backgroundColor)
        .cornerRadius(16)
        .padding(.top, 12)
        .onTapGesture {
            // Gentle but noticeable haptic for state change
            if isExpanded {
                Haptics.lightImpact(intensity: 0.4) // collapsing
            } else {
                Haptics.lightImpact(intensity: 0.3) // expanding
            }
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
                isExpanded.toggle()
            }
        }
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

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {

            Text(word)
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.mainBlack)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: playAudio) {
                SoundWavesView(isPlaying: isPlaying)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    private func playAudio() {
        Task {
            Haptics.selection()
            isPlaying = true
            await AudioManager.shared.play(word: word)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation {
                isPlaying = false
            }
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
            explanation: "Используется для описания вкусной еды или напитков.",
            breakdown: "Происходит от sabor (вкус) + -oso (обладающий качеством)",
            tag: "Golden",
            onDelete: {}
        )
        
        WordCardView(
            word: "Chido",
            translation: "Круто",
            type: "adjective",
            example: "La fiesta estuvo chido y divertida.",
            comment: nil,
            explanation: "Мексиканский разговорный термин, означающий что-то классное или приятное.",
            breakdown: nil,
            tag: "Slang",
            onDelete: {}
        )
        
        WordCardView(
            word: "食べ物",
            translation: "Еда",
            type: "noun",
            example: "この食べ物はとてもおいしいです。",
            comment: nil,
            explanation: "Общее слово для обозначения еды или продуктов питания.",
            breakdown: "食 (есть) + べる (глагольная основа) + 物 (вещь) — буквально: 'то, что едят'",
            tag: "Chat",
            onDelete: {}
        )
        
    }
    .padding()
}

