import SwiftUI

struct PersonalDetailsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    @State private var tempName: String = ""
    @State private var tempEmail: String = ""
    @State private var showEmailError = false
    @State private var showToast = false

    private var isEmailValid: Bool {
        let email = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty { return true }
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private var isNameValid: Bool {
        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 40
    }

    private var canSave: Bool {
        isNameValid && isEmailValid
    }

    private var nameCounterText: String {
        "\(min(tempName.count, 40))/40"
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("Personal details")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name *")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(Color.mainGrey)

                    FormTextField(
                        title: "Your name",
                        text: $tempName,
                        focusedColor: .mainGrey
                    )
                    .overlay(alignment: .trailing) {
                        Text(nameCounterText)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(Color.mainGrey.opacity(0.6))
                            .padding(.trailing, 16)
                            .allowsHitTesting(false)
                    }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: tempName) { newValue in
                        if newValue.count > 40 {
                            tempName = String(newValue.prefix(40))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(Color.mainGrey)

                    FormTextField(
                        title: "Email",
                        text: $tempEmail,
                        focusedColor: .mainGrey
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .onChange(of: tempEmail) { _ in
                        let trimmed = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                        showEmailError = !isEmailValid && !trimmed.isEmpty
                    }

                    if showEmailError {
                        Text("Please enter a valid email")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(themeStore.accentRed)
                            .padding(.top, 4)
                    }
                }

                Button(action: {
                    let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedEmail = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)

                    if !trimmedName.isEmpty && trimmedName.count <= 40 && isEmailValid {
                        userName = trimmedName
                        userEmail = trimmedEmail.lowercased()
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            dismiss()
                        }
                    } else {
                        showEmailError = !isEmailValid && !trimmedEmail.isEmpty
                    }
                }) {
                    Text("Save")
                        .duo3DStyle(Color.accentBlack, isDisabled: !canSave)
                }
                .buttonStyle(Duo3DButtonStyle())
                .disabled(!canSave)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 30)

            if showToast {
                BannerToastView(type: .success, message: "Saved", duration: 1.5)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            tempName = userName
            tempEmail = userEmail
        }
    }
}

#Preview {
    PersonalDetailsView()
}

