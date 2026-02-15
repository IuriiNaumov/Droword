import SwiftUI

struct TagsView: View {
    @Binding var selectedTag: String?
    var compact: Bool = false
    var hasGoldenWords: Bool = false

    static let allTags: [(name: String, color: Color)] = [
        ("Golden", Color(hexRGB: 0xFCDD9D)),
        ("Chat",   Color(hexRGB: 0xCDEBF1)),
        ("Travel", Color(hexRGB: 0xDEF1D0)),
        ("Street", Color(hexRGB: 0xF8E5E5)),
        ("Movies", Color(hexRGB: 0xCBCEEA)),
    ]

    var visibleTags: [(name: String, color: Color)] {
        Self.allTags.filter { tag in
            tag.name == "Golden" ? hasGoldenWords : true
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 10 : 14) {
                ForEach(visibleTags, id: \.name) { tag in
                    let isSelected = selectedTag == tag.name
                    let baseColor = tag.color
                    let textColor = darkerShade(of: baseColor, by: 0.45).opacity(isSelected ? 1.0 : 0.9)

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedTag = isSelected ? nil : tag.name
                        }
                    } label: {
                        Text(tag.name)
                            .font(.custom("Poppins-Medium", size: compact ? 13 : 15))
                            .foregroundColor(textColor)
                            .frame(minWidth: 120)
                            .padding(.vertical, compact ? 12 : 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(baseColor.opacity(isSelected ? 0.95 : 0.32))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(baseColor.opacity(isSelected ? 1.0 : 0.35), lineWidth: isSelected ? 1.4 : 1.0)
                            )
                            .scaleEffect(isSelected ? 1.06 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, compact ? 10 : 6)
            .padding(.vertical, compact ? 6 : 10)
        }
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
            TagsView(selectedTag: .constant("Street"), hasGoldenWords: false)
        }
        .padding(.vertical, 30)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
