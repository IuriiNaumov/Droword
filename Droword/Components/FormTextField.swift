import SwiftUI
import Combine

enum FormTextFieldStatus {
    case normal
    case correct
    case almost
    case wrong
}

struct FormTextField: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let title: String
    @Binding var text: String
    var maxLength: Int? = nil
    var showCounter: Bool = false
    var status: FormTextFieldStatus = .normal
    var isDisabled: Bool = false
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disableAutocorrection: Bool = false
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    var externalFocus: FocusState<Bool>.Binding? = nil

    @FocusState private var internalFocus: Bool

    private var fillColor: Color {
        switch status {
        case .normal:
            return themeStore.dividerColor.opacity(0.55)
        case .correct:
            return themeStore.accentGreen.opacity(0.12)
        case .almost:
            return themeStore.accentGold.opacity(0.12)
        case .wrong:
            return themeStore.accentRed.opacity(0.12)
        }
    }

    var body: some View {
        field
            .font(themeStore.regular(16))
            .padding(.horizontal, 14)
            .padding(.vertical, 19)
            .foregroundStyle(themeStore.mainText)
            .tint(themeStore.mainAccentColor)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                    .fill(fillColor)
            )
            .disabled(isDisabled)
            .opacity(isDisabled && status == .normal ? 0.85 : 1)
    }

    @ViewBuilder
    private var field: some View {
        let base = TextField(title, text: $text)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(disableAutocorrection)
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }
            .onReceive(Just(text)) { newValue in
                if let limit = maxLength, newValue.count > limit {
                    text = String(newValue.prefix(limit))
                }
            }

        if let externalFocus {
            base.focused(externalFocus)
        } else {
            base.focused($internalFocus)
        }
    }
}

#Preview("FormTextField Variants") {
    VStack(spacing: 16) {
        StatefulPreviewWrapper("") { binding in
            FormTextField(title: "Name", text: binding)
        }

        StatefulPreviewWrapper("Hello") { binding in
            FormTextField(
                title: "Username",
                text: binding,
                maxLength: 12,
                showCounter: true
            )
        }
    }
    .padding()
    .background(Color("CardBackground"))
    .environmentObject(ThemeStore())
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
