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
        VStack(spacing: 16) {
            Spacer(minLength: 20)
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    ZStack(alignment: .trailing) {
                        TextField("Enter your name", text: $tempName)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(tempName.count > 40 ? Color("red") : Color.clear, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)

                        Text(nameCounterText)
                            .font(.caption)
                            .foregroundColor(tempName.count > 40 ? Color("red") : Color.secondary)
                            .padding(.trailing, 40)

                    }.padding(.bottom, 20)
                }

                VStack(spacing: 8) {
                    Text("Email")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    if showEmailError {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundColor(Color("red"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    }

                    TextField("Enter your email (optional)", text: $tempEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(showEmailError ? Color("red") : Color.clear, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
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
