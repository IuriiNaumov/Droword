import SwiftUI
import UIKit

struct RoundedInputField: View {
    enum FieldStyle {
        case plain
        case secure
    }

    let placeholder: String
    @Binding var text: String
    var style: FieldStyle = .plain

    @State private var isSecureHidden: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.divider, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.cardBackground)
                )

            HStack(spacing: 4) {
                Group {
                    if style == .secure && isSecureHidden {
                        SecureField(placeholder, text: $text)
                            .textContentType(.password)
                    } else {
                        TextField(placeholder, text: $text)
                            .textContentType(style == .secure ? .password : .emailAddress)
                            .keyboardType(style == .secure ? .default : .emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                }
                .font(.custom("Poppins-Regular", size: 22))
                .foregroundStyle(Color.primary.opacity(0.9))

                if style == .secure {
                    Button(action: { isSecureHidden.toggle() }) {
                        Image(systemName: isSecureHidden ? "eye.slash" : "eye")
                            .foregroundStyle(.primary)
                            .font(.custom("Poppins-Regular", size: 18))
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(height: 72)
    }
}
