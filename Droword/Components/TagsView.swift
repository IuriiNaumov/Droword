import SwiftUI

struct TagsView: View {
    @Binding var selectedTag: String?
    @ObservedObject private var tagStore = TagStore.shared
    var compact: Bool = false
    var hasGoldenWords: Bool = false
    var showManagementControls: Bool = true
    var onAddTag: (() -> Void)? = nil
    @State private var isDeleteMode: Bool = false

    var allTags: [(name: String, color: Color)] {
        TagStore.shared.tags.map { ($0.name, Color(fromHexString: $0.colorHex) ?? Color.gray) } + [
            ("Golden", Color(hexRGB: 0xFCDD9D)),
            ("Chat",   Color(hexRGB: 0xCDEBF1)),
            ("Travel", Color(hexRGB: 0xDEF1D0)),
            ("Street", Color(hexRGB: 0xF8E5E5)),
            ("Movies", Color(hexRGB: 0xCBCEEA)),
        ]
    }

    var visibleTags: [(name: String, color: Color)] {
        allTags.filter { tag in
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
                            let willSelect = !(selectedTag == tag.name)
                            selectedTag = willSelect ? tag.name : nil
                        }
                        Haptics.selection()
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
                                    .stroke(baseColor.opacity(0.0), lineWidth: 0)
                            )
                            .scaleEffect(isSelected ? 1.06 : 1.0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelected)
                            .modifier(WiggleEffect(isActive: isDeleteMode && TagStore.shared.tags.contains(where: { $0.name == tag.name })))
                            .overlay(alignment: .topTrailing) {
                                if isDeleteMode, TagStore.shared.tags.contains(where: { $0.name == tag.name }) {
                                    Button(action: {
                                        TagStore.shared.removeTag(named: tag.name)
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 20, height: 20)
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                    }
                                    .offset(x: 6, y: -6)
                                    .buttonStyle(.plain)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }

                if showManagementControls {
                    Button(action: { onAddTag?() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.toastAndButtons))
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)

                    Button(action: { withAnimation { isDeleteMode.toggle() } }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 32, height: 32)
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, compact ? 10 : 6)
            .padding(.vertical, compact ? 6 : 10)
        }
    }
}

private struct WiggleEffect: ViewModifier {
    let isActive: Bool
    @State private var angle: Double = 0
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isActive ? sin(angle) * 2.0 : 0))
            .animation(.linear(duration: 0.12).repeatForever(autoreverses: true), value: isActive ? angle : 0)
            .onAppear { if isActive { start() } }
            .onChange(of: isActive) { newValue in
                if newValue { start() }
            }
    }
    private func start() {
        angle = 0
        withAnimation(.linear(duration: 0.12).repeatForever(autoreverses: true)) {
            angle = .pi * 2
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

