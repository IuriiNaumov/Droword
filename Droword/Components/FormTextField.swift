import SwiftUI
import Combine

struct FormTextField: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let title: String
    @Binding var text: String
    var focusedColor: Color = Color("MainBlack")
    var maxLength: Int? = nil
    var showCounter: Bool = false

    @FocusState private var isFocused: Bool

    private let counterFont = Font.custom("Poppins-Regular", size: 13)

    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(title, text: $text)
                .focused($isFocused)
                .onReceive(Just(text)) { newValue in
                    if let limit = maxLength, newValue.count > limit {
                        text = String(newValue.prefix(limit))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 19)
                .foregroundColor(themeStore.mainText)
                .tint(themeStore.mainAccentColor)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeStore.dividerColor.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isFocused ? themeStore.mainAccentColor : Color.clear, lineWidth: 2)
                )

            if showCounter, let limit = maxLength {
                Text("\(text.count)/\(limit)")
                    .font(counterFont)
                    .foregroundColor(themeStore.secondaryText)
                    .padding(.trailing, 14)
            }
        }
    }
}

#Preview("FormTextField Variants") {
    VStack(spacing: 16) {
        StatefulPreviewWrapper("") { binding in
            FormTextField(title: "Name", text: binding)
        }

        StatefulPreviewWrapper("Hello") { binding in
            FormTextField(title: "Username",
                          text: binding,
                          focusedColor: Color.accentBlue,
                          maxLength: 12,
                          showCounter: true)
        }
    }
    .padding()
    .background(Color("CardBackground"))
}


private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
