import SwiftUI

struct PersonalDetailsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.userName) private var userName: String = ""

    @State private var tempName: String = ""
    @State private var showToast = false

    private var isNameValid: Bool {
        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 40
    }

    private var canSave: Bool {
        isNameValid
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Personal details")
                    .sheetTitle()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name *")
                            .font(themeStore.regular(18))
                            .foregroundColor(themeStore.secondaryText)
                        Spacer()
                        Text("\(tempName.count)/40")
                            .font(themeStore.regular(14))
                            .foregroundColor(themeStore.secondaryText.opacity(0.6))
                    }

                    FormTextField(
                        title: "Your name",
                        text: $tempName,
                        focusedColor: themeStore.secondaryText,
                        maxLength: 40
                    )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
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
                        .duo3DStyle(themeStore.mainAccentColor, isDisabled: !canSave)
                }
                .buttonStyle(Duo3DButtonStyle())
                .disabled(!canSave)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        CloseButtonIcon()
                            .environmentObject(themeStore)
                    }
                }
            }
            .overlay {
                if showToast {
                    BannerToastView(type: .success, message: String(localized: "Saved"), duration: 1.5)
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

