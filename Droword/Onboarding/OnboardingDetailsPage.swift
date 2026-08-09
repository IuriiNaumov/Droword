import SwiftUI

struct OnboardingDetailsPage: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @AppStorage(AppStorageKeys.userName) private var userName: String = ""
    
    @State private var tempName: String = ""
    
    private var isNameValid: Bool {
        !tempName.isEmpty && tempName.count <= 40
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name")
                            .font(themeStore.medium(14))
                            .foregroundStyle(themeStore.mainText.opacity(0.75))
                        Spacer()
                        Text("\(tempName.count)/40")
                            .font(themeStore.regular(12))
                            .foregroundStyle(tempName.count > 40 ? Color.accentRed : themeStore.secondaryText)
                    }
                    .padding(.horizontal, 4)

                    TextField("Enter your name", text: $tempName)
                        .font(themeStore.regular(16))
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(themeStore.cardBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(tempName.count > 40 ? Color.accentRed : themeStore.dividerColor, lineWidth: 2)
                        )
                }

            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeStore.appBg)
        .onAppear {
            tempName = userName
        }
        .onChange(of: tempName) { _, newValue in
            if !newValue.isEmpty && newValue.count <= 40 {
                userName = newValue
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
