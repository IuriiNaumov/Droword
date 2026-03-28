import SwiftUI

struct OnboardingDetailsPage: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @AppStorage("userName") private var userName: String = ""
    
    @State private var tempName: String = ""
    
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
                        .foregroundColor(themeStore.mainText.opacity(0.75))
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
                                    .fill(themeStore.cardBg)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(tempName.count > 40 ? Color.accentRed : themeStore.dividerColor, lineWidth: 2)
                            )

                        Text(nameCounterText)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(tempName.count > 40 ? Color.accentRed: themeStore.secondaryText)
                            .padding(.trailing, 16)
                    }
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
