import SwiftUI

struct ZoomerSticker: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let text: String
    var icon: String? = nil
    var fill: Color? = nil
    var foreground: Color = .white
    var rotation: Double = 0
    var fontSize: CGFloat = 13

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: fontSize, weight: .semibold))
            }
            Text(text)
                .font(themeStore.bold(fontSize))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(fill ?? themeStore.mainAccentColor)
        )
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

struct ZoomerCountBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let value: Int
    var rotation: Double = 0

    @State private var appeared = false

    var body: some View {
        Text("\(value)")
            .font(themeStore.display(26))
            .foregroundStyle(themeStore.mainAccentColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.mainAccentColor.opacity(0.12))
            )
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
    }
}

struct ZoomerTitleModifier: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .font(themeStore.display(size))
            .foregroundStyle(themeStore.mainText)
            .tracking(-0.4)
    }
}

extension View {
    func zoomerTitle(_ size: CGFloat = 28) -> some View {
        modifier(ZoomerTitleModifier(size: size))
    }
}
