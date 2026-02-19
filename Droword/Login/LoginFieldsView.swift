import SwiftUI

struct LoginFieldsView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreeToTerms: Bool = false
    @FocusState private var focusedField: Field?
    private enum Field { case email, password }

    @State private var emailError: String? = nil
    @State private var isKeyboardActive: Bool = false
    @State private var didAttemptLogin: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShowingSignUp: Bool = false

    private var isEmailValid: Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    private var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty && agreeToTerms
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        Text("Login")
                            .font(.custom("Poppins-Bold", size: 44))
                            .foregroundStyle(Color(.label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(spacing: 0) {
                                TextField("Email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 24)
                                    .focused($focusedField, equals: .email)
                                    .onChange(of: email) { _, newValue in
                                        if didAttemptLogin {
                                            emailError = email.isEmpty || isEmailValid ? nil : "Email is not valid"
                                        }
                                    }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(focusedField == .email ? Color.fromHex(0x3D3D3D, alpha: 0.12) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(focusedField == .email ? Color.fromHex(0x3D3D3D) : Color(.separator), lineWidth: focusedField == .email ? 1.5 : 1)
                            )
                            
                            ZStack(alignment: .leading) {
                                if didAttemptLogin, let emailError = emailError {
                                    Text(emailError)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.red)
                                        .padding(.horizontal, 4)
                                        .accessibilityLabel("Email error: \(emailError)")
                                }
                            }
                            .frame(height: 16)
                        }
                        
                        VStack(spacing: 8) {
                            VStack(spacing: 0) {
                                LoginPasswordField(placeholder: "Password", text: $password)
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .focused($focusedField, equals: .password)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(focusedField == .password ? Color.fromHex(0x3D3D3D, alpha: 0.12) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(focusedField == .password ? Color.fromHex(0x3D3D3D) : Color(.separator), lineWidth: focusedField == .password ? 1.5 : 1)
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
                            .accessibilityLabel("Agree to terms")
                            .accessibilityAddTraits(agreeToTerms ? .isSelected : [])
                        }
                        .padding(.top, 4)
                        
                        Button(action: {
                            didAttemptLogin = true
                            emailError = email.isEmpty || isEmailValid ? nil : "Email is not valid"
                        }) {
                            Text("Login")
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

                        HStack(spacing: 6) {
                            Text("You don't have an account?")
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundStyle(Color("MainBlack"))
                            Button(action: {
                                isShowingSignUp = true
                            }) {
                                Text("Sign Up")
                                    .font(.custom("Poppins-Bold", size: 16))
                                    .foregroundStyle(Color(.label))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Sign Up")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)
                }
                .scrollDismissesKeyboard(.interactively)
                .padding(.bottom, keyboardHeight)
                .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                    guard let info = notification.userInfo,
                          let endFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                          let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
                          let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
                    let endHeight = max(0, geo.frame(in: .global).maxY - endFrame.minY)
                    let curve = UIView.AnimationCurve(rawValue: Int(curveRaw)) ?? .easeInOut
                    let animation: Animation
                    switch curve {
                    case .easeInOut:
                        animation = .easeInOut(duration: duration)
                    case .easeIn:
                        animation = .easeIn(duration: duration)
                    case .easeOut:
                        animation = .easeOut(duration: duration)
                    case .linear:
                        animation = .linear(duration: duration)
                    @unknown default:
                        animation = .easeInOut(duration: duration)
                    }
                    withAnimation(animation) {
                        keyboardHeight = endHeight
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        keyboardHeight = 0
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .navigationDestination(isPresented: $isShowingSignUp) {
                    SignUpFieldsView()
                }
            }
        }
    }
}

struct LoginPasswordField: View {
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

#Preview {
    LoginFieldsView()
}

extension Color {
    static func fromHex(_ hex: UInt, alpha: Double = 1.0) -> Color {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

