import SwiftUI
import Combine

struct FormTextField: View {
    let title: String
    @Binding var text: String
    var focusedColor: Color = .black
    var maxLength: Int? = nil
    var showCounter: Bool = false

    @FocusState private var isFocused: Bool

    private let labelFont = Font.custom("Poppins-Regular", size: 18)
    private let counterFont = Font.custom("Poppins-Regular", size: 13)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(labelFont)
                .foregroundColor(.gray)

            ZStack(alignment: .trailing) {
                TextField("", text: $text)
                    .focused($isFocused)
                    .onReceive(Just(text)) { newValue in
                        if let limit = maxLength, newValue.count > limit {
                            text = String(newValue.prefix(limit))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 19)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isFocused ? focusedColor : .clear, lineWidth: 1.5)
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                    )

                if showCounter, let limit = maxLength {
                    Text("\(text.count)/\(limit)")
                        .font(counterFont)
                        .foregroundColor(.gray)
                        .padding(.trailing, 14)
                }
            }
        }
    }
}
