import SwiftUI

struct ChatBubbleView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let message: SceneChatMessage
    let showHint: Bool
    let onHint: (String) -> Void

    private var isUser: Bool { message.role == .user }

    private var bubbleFill: Color {
        if isUser { return themeStore.mainAccentColor }
        if themeStore.isGlass { return themeStore.dividerColor.opacity(0.55) }
        return themeStore.cardBg
    }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            textBubble
            if isUser, message.usedWord {
                Text("You used it.")
                    .font(themeStore.medium(12))
                    .foregroundStyle(themeStore.accentGreen)
            }
            if let nudge = message.nudge, !nudge.isEmpty {
                Text(nudge)
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
            }
            if showHint, message.role == .assistant, let hint = message.hint, !hint.isEmpty {
                Button {
                    onHint(hint)
                } label: {
                    Text(hint)
                        .font(themeStore.medium(13))
                        .foregroundStyle(themeStore.mainAccentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(themeStore.mainAccentColor.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var textBubble: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            Text(message.text)
                .font(themeStore.regular(16))
                .foregroundStyle(isUser ? Color.white : themeStore.mainText)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(bubbleFill)
                )
            if !isUser { Spacer(minLength: 48) }
        }
    }
}
