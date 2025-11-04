import SwiftUI

struct TagsView: View {
    @Binding var selectedTag: String?
    var showTitle: Bool = true
    var compact: Bool = false

    // Единый список тегов и цветов
    static let allTags: [(name: String, color: Color)] = [
        ("Social", Color(hexRGB: 0xF2D0F9)),
        ("Chat", Color(hexRGB: 0xB3D9ED)),
        ("Apps", Color(hexRGB: 0xD9E764)),
        ("Street", Color(hexRGB: 0xFFD7A8)),
        ("Movies", Color(hexRGB: 0xFF9387)),
        ("Travel", Color(hexRGB: 0xFFD66D)),
        ("Work", Color(hexRGB: 0xDCDCF3))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: compact ? 10 : 14) {
                    ForEach(Self.allTags, id: \.name) { tag in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTag = (selectedTag == tag.name) ? nil : tag.name
                            }
                        } label: {
                            Text(tag.name)
                                .font(.custom("Poppins-Medium", size: compact ? 13 : 15))
                                .foregroundColor(.black)
                                .padding(.horizontal, compact ? 14 : 18)
                                .padding(.vertical, compact ? 6 : 10)
                                .background(tag.color.opacity(selectedTag == tag.name ? 1.0 : 0.7))
                                .cornerRadius(compact ? 14 : 18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: compact ? 14 : 18)
                                        .stroke(selectedTag == tag.name
                                                ? tag.color.darker(by: 0.3)
                                                : .clear,
                                                lineWidth: 1.5)
                                )
                                .scaleEffect(selectedTag == tag.name ? 1.1 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, compact ? 4 : 8)
                .padding(.vertical, compact ? 6 : 10)
            }
        }
    }
}

