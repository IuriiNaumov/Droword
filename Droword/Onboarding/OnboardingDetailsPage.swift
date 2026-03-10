import SwiftUI

struct OnboardingDetailsPage: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    
    @State private var tempName: String = ""
    @State private var tempEmail: String = ""
    @State private var showEmailError = false
    
    private var isEmailValid: Bool {
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", #"^\S+@\S+\.\S+$"#)
        return emailPredicate.evaluate(with: tempEmail)
    }
    
    private var isNameValid: Bool {
        !tempName.isEmpty && tempName.count <= 40
    }
    
    private var nameCounterText: String {
        "\(tempName.count)/40"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.mainBlack.opacity(0.75))
                        .padding(.horizontal, 4)

                    ZStack(alignment: .trailing) {
                        TextField("Enter your name", text: $tempName)
                            .font(.custom("Poppins-Regular", size: 16))
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(tempName.count > 40 ? Color.red : Color.divider, lineWidth: 2)
                            )

                        Text(nameCounterText)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(tempName.count > 40 ? Color.red : Color.mainGrey)
                            .padding(.trailing, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.mainBlack.opacity(0.75))
                        .padding(.horizontal, 4)

                    if showEmailError {
                        Text("Please enter a valid email address")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }

                    TextField("Enter your email (optional)", text: $tempEmail)
                        .font(.custom("Poppins-Regular", size: 16))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(showEmailError ? Color.red : Color.divider, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .onAppear {
            tempName = userName
            tempEmail = userEmail
            showEmailError = !(tempEmail.isEmpty || isEmailValid)
        }
        .onChange(of: tempName) { newValue in
            if !newValue.isEmpty && newValue.count <= 40 {
                userName = newValue
            }
        }
        .onChange(of: tempEmail) { newValue in
            showEmailError = !(newValue.isEmpty || isEmailValid)
            if isEmailValid || newValue.isEmpty {
                userEmail = newValue
            }
        }
    }
}

struct OnboardingDetailsPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingDetailsPage()
                .environment(\.colorScheme, .light)
            OnboardingDetailsPage()
                .environment(\.colorScheme, .dark)
        }
    }
}
