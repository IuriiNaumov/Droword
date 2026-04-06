import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .sheetTitle()

                Text("Last updated: April 2026")
                    .font(themeStore.regular(13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, -12)

                Group {
                    policySection(
                        title: "1. Introduction",
                        body: "This Privacy Policy describes how Droword (\"the App,\" \"we,\" \"us,\" or \"our\") handles information when you use the application.\n\nBy accessing or using the App, you agree to this Privacy Policy."
                    )

                    policySection(
                        title: "2. Data Storage and Processing",
                        body: "All data created and used within the App — including words, learning progress, settings, and preferences — is stored locally on your device.\n\nWe do not collect, store, or process personal data on our servers."
                    )

                    policySection(
                        title: "3. Use of Third-Party Services",
                        body: "The App uses limited third-party services strictly for providing core functionality.\n\nAI Translation\nWhen you add or translate a word, the text may be sent to a third-party AI service (Anthropic Claude) to generate translations, explanations, and examples. Only the text you provide is transmitted. No personal data is intentionally collected or included. Requests are processed in real time and are not stored by the App.\n\nText-to-Speech\nTo provide pronunciation features, the App uses the OpenAI Text-to-Speech API. Only the word or phrase is transmitted. No personal data is included in the request."
                    )

                    policySection(
                        title: "4. Photos and Camera Access",
                        body: "If you choose to set a profile image, the image is stored locally on your device. The App does not upload, store, or process images on external servers."
                    )

                    policySection(
                        title: "5. Notifications",
                        body: "The App may send local notifications to remind you to practice. Notifications are scheduled locally. No external servers are involved. No personal data is used for notification logic."
                    )
                }
                .padding(.horizontal)

                Group {
                    policySection(
                        title: "6. Analytics and Tracking",
                        body: "We respect your privacy. The App does not use analytics tools, tracking technologies, or advertising SDKs. No usage data is collected or shared."
                    )

                    policySection(
                        title: "7. Data Retention and Deletion",
                        body: "All data remains on your device unless you choose to delete it.\n\nYou may delete your data at any time via Settings → Dictionary → Clear All Words. Uninstalling the App will permanently remove all stored data."
                    )

                    policySection(
                        title: "8. Your Privacy Rights",
                        body: "If you are located in the European Economic Area (EEA) or other regions with data protection laws, you have certain rights.\n\nSince the App does not collect or store personal data, most traditional data rights (such as access, correction, or deletion requests) do not apply. However, you retain full control over your data because all data is stored locally on your device and you can delete it at any time."
                    )

                    policySection(
                        title: "9. Children's Privacy",
                        body: "The App is not directed to children under the age of 13 (or equivalent minimum age in your jurisdiction). We do not knowingly collect personal data from children."
                    )

                    policySection(
                        title: "10. Security",
                        body: "We take reasonable measures to protect your data. Since all data is stored locally on your device, the security of your data depends on your device's security settings."
                    )

                    policySection(
                        title: "11. Changes to This Privacy Policy",
                        body: "We may update this Privacy Policy from time to time. Changes will be reflected by updating the \"Last updated\" date. Continued use of the App after changes constitutes acceptance of the updated policy."
                    )

                    policySection(
                        title: "12. Contact",
                        body: "If you have any questions about this Privacy Policy, please contact us via the App Store support link."
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(themeStore.bold(18))
                .foregroundColor(.primary)
            Text(body)
                .font(themeStore.regular(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(themeStore.cardBg))
    }
}
