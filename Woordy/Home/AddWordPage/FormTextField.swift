import SwiftUI

struct FormTextField: View {
    let title: String
    @Binding var text: String
    var focusedColor: Color = .black
    var maxLength: Int? = nil
    var showCounter: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.gray)

            ZStack(alignment: .trailing) {
                TextField("", text: $text)
                    .focused($isFocused)
                    .onChange(of: text) { newValue in
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
                            .stroke(isFocused ? focusedColor : .clear, lineWidth: 1.5)
                    )

                if showCounter, let limit = maxLength {
                    Text("\(text.count)/\(limit)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.gray)
                        .padding(.trailing, 14)
                }
            }
        }
    }
}
