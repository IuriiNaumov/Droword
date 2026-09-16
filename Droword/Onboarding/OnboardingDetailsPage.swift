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

                    FormTextField(
                        title: String(localized: "Enter your name"),
                        text: $tempName,
                        maxLength: 40,
                        status: tempName.count > 40 ? .wrong : .normal,
                        autocapitalization: .words,
                        disableAutocorrection: true
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
