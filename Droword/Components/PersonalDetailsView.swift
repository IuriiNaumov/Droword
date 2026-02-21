import SwiftUI

struct PersonalDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    @State private var tempName: String = ""
    @State private var tempEmail: String = ""
    @State private var showEmailError = false

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
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    Text("Personal details")
                        .font(.custom("Poppins-Bold", size: 26))
                        .foregroundColor(.mainBlack)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name *")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(Color(.mainGrey))

                        FormTextField(
                            title: "Your name",
                            text: $tempName,
                            focusedColor: .mainGrey
                        )
                        .overlay(alignment: .trailing) {
                            Text(nameCounterText)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(Color(.mainGrey).opacity(0.6))
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
                            .foregroundColor(Color(.mainGrey))

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
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.mainGrey)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedEmail = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)

                        if !trimmedName.isEmpty && trimmedName.count <= 40 && isEmailValid {
                            userName = trimmedName
                            userEmail = trimmedEmail.lowercased()
                            dismiss()
                        } else {
                            showEmailError = !isEmailValid && !trimmedEmail.isEmpty
                        }
                    }
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(canSave ? Color.toastAndButtons : Color.mainGrey)
                    .disabled(!canSave)
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
