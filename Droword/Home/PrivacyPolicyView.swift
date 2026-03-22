import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)

                Group {
                    policySection(
                        title: "Data Storage",
                        body: "All your data — words, progress, settings and preferences — is stored locally on your device. Droword does not collect, transmit or store any personal data on external servers."
                    )

                    policySection(
                        title: "AI Translation",
                        body: "When you add or translate a word, the text is sent to a third-party AI service (Anthropic Claude) to generate translations, explanations and examples. No personal information is included in these requests."
                    )

                    policySection(
                        title: "Text-to-Speech",
                        body: "Audio pronunciation is generated using the OpenAI Text-to-Speech API. Only the word or phrase text is sent — no personal data is transmitted."
                    )

                    policySection(
                        title: "Photos & Camera",
                        body: "If you choose to set a profile photo, the image is stored only on your device. Droword does not upload your photos anywhere."
                    )

                    policySection(
                        title: "Notifications",
                        body: "Droword may send local notifications to remind you to practice. These are scheduled entirely on your device and do not involve any external service."
                    )

                    policySection(
                        title: "Analytics & Tracking",
                        body: "Droword does not use any analytics, tracking or advertising SDKs. Your usage data stays on your device."
                    )

                    policySection(
                        title: "Data Deletion",
                        body: "You can delete all your data at any time from Settings → Dictionary → Clear All Words. Removing the app from your device deletes all stored data permanently."
                    )

                    policySection(
                        title: "Contact",
                        body: "If you have questions about this privacy policy, please reach out via the App Store support link."
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Poppins-Medium", size: 17))
                .foregroundColor(.primary)
            Text(body)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(themeStore.cardBg))
    }
}
