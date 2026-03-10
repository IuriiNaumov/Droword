import SwiftUI

struct TagsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTag: String?
    @ObservedObject private var tagStore = TagStore.shared
    var compact: Bool = false
    var hasGoldenWords: Bool = false
    var showManagementControls: Bool = true
    var onAddTag: (() -> Void)? = nil
    @State private var isDeleteMode: Bool = false

    private let builtInNames: Set<String> = ["Golden", "Chat", "Travel", "Street", "Movies"]

    var allTags: [(name: String, color: Color, isCustom: Bool)] {
        let custom: [(name: String, color: Color, isCustom: Bool)] = TagStore.shared.tags.map {
            ($0.name, Color(fromHexString: $0.colorHex) ?? Color.gray, true)
        }
        let builtIn: [(name: String, color: Color, isCustom: Bool)] = [
            ("Golden", Color.accentGold, false),
            ("Chat",   Color.accentBlue, false),
            ("Travel", Color.accentGreen, false),
            ("Street", Color.accentPink, false),
            ("Movies", Color.accentPurple, false),
        ]
        return custom + builtIn
    }

    var visibleTags: [(name: String, color: Color, isCustom: Bool)] {
        allTags.filter { tag in
            tag.name == "Golden" ? hasGoldenWords : true
        }
    }

    private var hasCustomTags: Bool {
        !tagStore.tags.isEmpty
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 10 : 14) {
                ForEach(visibleTags, id: \.name) { tag in
                    let isSelected = selectedTag == tag.name
                    let baseColor = tag.color
                    let dimmed = isDeleteMode && !tag.isCustom
                    let textColor: Color = colorScheme == .dark
                        ? .white.opacity(isSelected ? 1.0 : 0.9)
                        : darkerShade(of: baseColor, by: 0.45).opacity(isSelected ? 1.0 : 0.9)

                    Button {
                        if isDeleteMode {
                            if tag.isCustom {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    TagStore.shared.removeTag(named: tag.name)
                                    if selectedTag == tag.name { selectedTag = nil }
                                }
                                Haptics.selection()
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTag = selectedTag == tag.name ? nil : tag.name
                            }
                            Haptics.selection()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isDeleteMode && tag.isCustom {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            Text(tag.name)
                                .font(.custom("Poppins-Medium", size: compact ? 13 : 15))
                                .foregroundColor(textColor)

                            if isDeleteMode && !tag.isCustom {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.5))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, compact ? 8 : 10)
                        .padding(.horizontal, compact ? 24 : 28)
                        .background(
                            Capsule()
                                .fill(baseColor.opacity(dimmed ? 0.15 : (isSelected ? 0.95 : 0.32)))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isDeleteMode && tag.isCustom ? Color.accentRed.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                        .scaleEffect(isSelected && !isDeleteMode ? 1.06 : 1.0)
                        .opacity(dimmed ? 0.5 : 1.0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelected)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isDeleteMode)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeleteMode && !tag.isCustom)
                }

                if showManagementControls {
                    Button(action: { onAddTag?() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.accentBlue))
                            
                    }
                    .buttonStyle(.plain)
                    .opacity(isDeleteMode ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isDeleteMode)

                    if hasCustomTags {
                        Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isDeleteMode.toggle() } }) {
                            Image(systemName: isDeleteMode ? "checkmark" : "pencil")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isDeleteMode ? .white : .mainGrey)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(isDeleteMode ? Color.red : Color.mainGrey.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, compact ? 10 : 0)
            .padding(.vertical, compact ? 16 : 10)
        }
        .onChange(of: tagStore.tags.count) { newCount in
            if newCount == 0 && isDeleteMode {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDeleteMode = false
                }
            }
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
                .foregroundColor(Color.mainBlack)
                .padding(.horizontal)

            TagsView(selectedTag: .constant(nil), hasGoldenWords: true)
            TagsView(selectedTag: .constant("Chat"), hasGoldenWords: false)
        }
        .padding(.vertical, 30)
        .background(Color.white)
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
