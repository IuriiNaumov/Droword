import SwiftUI

struct SignUpFieldsView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreeToTerms: Bool = false
    @FocusState private var focusedField: Field?
    private enum Field { case email, password }

    @State private var emailError: String? = nil
    @State private var didAttemptSignUp: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    private var isEmailValid: Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && agreeToTerms
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Sign Up")
                        .font(.custom("Poppins-Bold", size: 44))
                        .foregroundStyle(Color(.label))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(spacing: 0) {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .font(.custom("Poppins-Regular", size: 17))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 24)
                                .focused($focusedField, equals: .email)
                                .onChange(of: email) { _, _ in
                                    if didAttemptSignUp {
                                        emailError = email.isEmpty || isEmailValid ? nil : "Email is not valid"
                                    }
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(focusedField == .email ? Color(hex: 0x3D3D3D, alpha: 0.12)
                                      : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(focusedField == .email ? Color(hex: 0x3D3D3D)
                                        : Color(.separator),
                                        lineWidth: focusedField == .email ? 1.5 : 1)
                        )

                        ZStack(alignment: .leading) {
                            if let emailError = emailError, didAttemptSignUp {
                                Text(emailError)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.red)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .frame(height: 16)
                    }

                    VStack(spacing: 8) {
                        VStack(spacing: 0) {
                            PasswordMaskedField(placeholder: "Password", text: $password)
                                .font(.custom("Poppins-Regular", size: 17))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .focused($focusedField, equals: .password)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(focusedField == .password ? Color(hex: 0x3D3D3D, alpha: 0.12)
                                      : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(focusedField == .password ? Color(hex: 0x3D3D3D)
                                        : Color(.separator),
                                        lineWidth: focusedField == .password ? 1.5 : 1)
                        )
                    }

                    HStack(spacing: 12) {
                        Text("I agree with term of use")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundStyle(Color(.label))
                            .onTapGesture { agreeToTerms.toggle() }

                        Spacer()

                        Button(action: { agreeToTerms.toggle() }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color(.separator), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(agreeToTerms ? Color("MainBlack") : Color.clear)
                                    )
                                    .frame(width: 28, height: 24)

                                if agreeToTerms {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: {
                        didAttemptSignUp = true
                        emailError = email.isEmpty || isEmailValid ? nil : "Email is not valid"
                    }) {
                        Text("Sign Up")
                            .font(.custom("Poppins-Regular", size: 24))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .fill(Color("MainBlack"))
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(isFormValid ? 1 : 0.6)
                    .disabled(!isFormValid)

                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("OR")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.black)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.vertical, 4)

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                            Text("Sign up with Google")
                                .font(.custom("Poppins-Regular", size: 16))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundStyle(Color("MainBlack"))
                        Button(action: {}) {
                            Text("Log in")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundStyle(Color(.label))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 34)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geo.size.height)
                .animation(.easeInOut(duration: 0.2), value: focusedField)
            }
            .scrollDismissesKeyboard(.interactively)
            .padding(.bottom, keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                guard let info = notification.userInfo,
                      let endFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
                let endHeight = max(0, geo.frame(in: .global).maxY - endFrame.minY)
                withAnimation(.easeInOut(duration: duration)) {
                    keyboardHeight = endHeight
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

#Preview {
    SignUpFieldsView()
}

struct PasswordMaskedField: View {
    var placeholder: String
    @Binding var text: String
    @State private var isSecure: Bool = true
    @FocusState private var focused: Bool

    private let rowHeight: CGFloat = 44
    private let font: Font = .system(size: 17)

    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(font)
                        .foregroundStyle(Color(.placeholderText))
                }

                TextField("", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .opacity(isSecure ? 0.01 : 1)

                if isSecure {
                    Text(maskedString)
                        .font(font.monospaced())
                        .foregroundStyle(Color.purple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: rowHeight)
            .contentShape(Rectangle())
            .onTapGesture { focused = true }

            Button(action: {
                let wasFocused = focused
                withAnimation(.easeInOut(duration: 0.12)) { isSecure.toggle() }
                if wasFocused { focused = true }
            }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
        }
    }

    private var maskedString: String {
        guard !text.isEmpty else { return "" }
        return String(repeating: "*", count: text.count)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
