import SwiftUI
import Combine

struct FormTextField: View {
    let title: String
    @Binding var text: String
    var focusedColor: Color = Color(.mainBlack)
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
                .background(Color.cardBackground)
                .foregroundColor(.mainBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isFocused ? Color.mainBlack : .divider, lineWidth: 1.5)
                )
                .cornerRadius(12)

            if showCounter, let limit = maxLength {
                Text("\(text.count)/\(limit)")
                    .font(counterFont)
                    .foregroundColor(Color("MainGrey"))
                    .padding(.trailing, 14)
            }
        }
    }
}
