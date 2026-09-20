import SwiftUI

struct ChatSceneHeaderView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let word: String
    let translation: String
    let userTurns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tiny chat")
                .zoomerTitle(26)
                .environmentObject(themeStore)

            HStack(spacing: 8) {
                Text(word)
                    .font(themeStore.bold(15))
                    .foregroundStyle(themeStore.mainAccentColor)
                if !translation.isEmpty {
                    Text(translation)
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text("\(min(userTurns, 3))/3")
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.secondaryText)
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index < userTurns ? themeStore.mainAccentColor : themeStore.dividerColor.opacity(0.7))
                        .frame(height: 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

struct ChatTypingRow: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        HStack {
            LoadingStagesView(dotSize: 7, color: themeStore.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(themeStore.cardBg)
                )
            Spacer(minLength: 48)
        }
        .id("typing")
    }
}

struct ChatComposerBar: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @Binding var draft: String
    let canSend: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Your line", text: $draft, axis: .vertical)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.mainText)
                .lineLimit(1...4)
                .focused(isFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(themeStore.dividerColor.opacity(0.55))
                )
                .onSubmit(onSend)

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(
                            canSend ? themeStore.mainAccentColor : themeStore.secondaryText.opacity(0.35)
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(themeStore.appBg)
    }
}

struct ChatDoneBar: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let usedWord: Bool
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("That's the scene.")
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)
            Text(usedWord ? String(localized: "You used it.") : String(localized: "See you tomorrow."))
                .font(themeStore.regular(14))
                .foregroundStyle(usedWord ? themeStore.accentGreen : themeStore.secondaryText)
            Button(action: onDone) {
                Text("Done")
                    .duo3DStyle(themeStore.mainAccentColor)
            }
            .buttonStyle(Duo3DButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

#Preview("Header") {
    ChatSceneHeaderView(word: "hola", translation: "hello", userTurns: 1)
        .padding()
        .environmentObject(ThemeStore())
}

#Preview("Typing") {
    ChatTypingRow()
        .padding()
        .environmentObject(ThemeStore())
}

private struct ChatComposerBarPreview: View {
    @State private var draft = "Hola"
    @FocusState private var focused: Bool

    var body: some View {
        ChatComposerBar(draft: $draft, canSend: true, isFocused: $focused, onSend: {})
            .environmentObject(ThemeStore())
    }
}

#Preview("Composer") {
    ChatComposerBarPreview()
}

#Preview("Done") {
    ChatDoneBar(usedWord: true, onDone: {})
        .padding()
        .environmentObject(ThemeStore())
}
