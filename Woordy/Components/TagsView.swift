import SwiftUI

struct TagsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTag: String?
    var compact: Bool = false
    var hasGoldenWords: Bool = false

    static let allTags: [(name: String, color: Color)] = [
        ("Golden", Color(hexRGB: 0xFFC107)),
        ("Social", Color(hexRGB: 0xFFDFA4)),
        ("Chat",   Color(hexRGB: 0xB9E3FF)),
        ("Apps",   Color(hexRGB: 0xC6F6D5)),
        ("Street", Color(hexRGB: 0xFFC6C9)),
        ("Movies", Color(hexRGB: 0xE4D2FF)),
        ("Travel", Color(hexRGB: 0xFFF1B2)),
        ("Work",   Color(hexRGB: 0xBDF4F2)),
    ]

    var visibleTags: [(name: String, color: Color)] {
        Self.allTags.filter { tag in
            if tag.name == "Golden" {
                return hasGoldenWords
            } else {
                return true
            }
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 10 : 14) {
                ForEach(visibleTags, id: \.name) { tag in
                    let isSelected = selectedTag == tag.name
                    let baseColor = adaptiveColor(for: tag.color)
                    let darkerText = darkerShade(of: baseColor, by: 0.35)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTag = isSelected ? nil : tag.name
                        }
                    } label: {
                        Text(tag.name)
                            .font(.custom("Poppins-Medium", size: compact ? 13 : 15))
                            .foregroundColor(
                                isSelected ? darkerText : darkerText.opacity(0.9)
                            )
                            .frame(minWidth: 120)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        colorScheme == .dark
                                        ? baseColor.opacity(isSelected ? 0.25 : 0.15)
                                        : baseColor.opacity(isSelected ? 0.9 : 0.3)
                                    )
                            )


                            .scaleEffect(isSelected ? 1.05 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, compact ? 10 : 6)
            .padding(.vertical, compact ? 6 : 10)
        }
    }

    private func adaptiveColor(for color: Color) -> Color {
        guard colorScheme == .dark else { return color }
        return darkerShade(of: color, by: 0.2)
    }
}


#Preview {
    Group {
        VStack(alignment: .leading, spacing: 20) {
            Text("Light Mode")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(Color("MainBlack"))
                .padding(.horizontal)

            TagsView(selectedTag: .constant(nil), hasGoldenWords: true)
            TagsView(selectedTag: .constant("Chat"), hasGoldenWords: false)
        }
        .padding(.vertical, 30)
        .background(Color(hexRGB: 0xFFF8E7))
        .preferredColorScheme(.light)

        VStack(alignment: .leading, spacing: 20) {
            Text("Dark Mode")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.white)
                .padding(.horizontal)

            TagsView(selectedTag: .constant(nil), hasGoldenWords: true)
            TagsView(selectedTag: .constant("Work"), hasGoldenWords: false)
        }
        .padding(.vertical, 30)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
