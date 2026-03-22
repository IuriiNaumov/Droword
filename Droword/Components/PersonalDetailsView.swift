import SwiftUI

struct PersonalDetailsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName: String = ""

    @State private var tempName: String = ""
    @State private var showToast = false

    private var isNameValid: Bool {
        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 40
    }

    private var canSave: Bool {
        isNameValid
    }

    private var nameCounterText: String {
        "\(min(tempName.count, 40))/40"
    }

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("Personal details")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name *")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(themeStore.secondaryText)

                    FormTextField(
                        title: "Your name",
                        text: $tempName,
                        focusedColor: themeStore.secondaryText
                    )
                    .overlay(alignment: .trailing) {
                        Text(nameCounterText)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(themeStore.secondaryText.opacity(0.6))
                            .padding(.trailing, 16)
                            .allowsHitTesting(false)
                    }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: tempName) { _, newValue in
                        if newValue.count > 40 {
                            tempName = String(newValue.prefix(40))
                        }
                    }
                }

                Button(action: {
                    let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty && trimmedName.count <= 40 {
                        userName = trimmedName
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            dismiss()
                        }
                    }
                }) {
                    Text("Save")
                        .duo3DStyle(themeStore.buttonAccent, isDisabled: !canSave)
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
        }
    }
}

#Preview {
    PersonalDetailsView()
}

