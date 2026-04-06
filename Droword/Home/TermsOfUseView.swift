import SwiftUI

struct TermsOfUseView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Use")
                    .sheetTitle()

                Text("Last updated: April 2026")
                    .font(themeStore.regular(13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, -12)

                Group {
                    section(
                        title: "1. Acceptance of Terms",
                        body: "By downloading, installing, or using Droword (\"the App\"), you agree to be bound by these Terms of Use. If you do not agree, do not use the App."
                    )

                    section(
                        title: "2. Description of Service",
                        body: "Droword is a vocabulary learning application that helps users learn and practice words in foreign languages. The App provides AI-powered translations, text-to-speech pronunciation, spaced repetition review, quizzes, and other learning tools."
                    )

                    section(
                        title: "3. User Accounts and Data",
                        body: "The App does not require account registration. All your data — including words, learning progress, and settings — is stored locally on your device.\n\nYou are responsible for maintaining the security of your device and your data. We are not responsible for data loss resulting from device damage, loss, or unauthorized access."
                    )

                    section(
                        title: "4. Subscriptions and Payments",
                        body: "Droword offers optional paid subscriptions (\"Droword PRO\") that unlock additional features.\n\n• Payment is charged to your Apple ID account at confirmation of purchase.\n• Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.\n• Your account will be charged for renewal within 24 hours prior to the end of the current period.\n• You can manage and cancel subscriptions in your App Store account settings.\n• Prices are subject to change. Any price changes will take effect at the start of the next subscription period.\n• No refunds are provided for partial subscription periods."
                    )

                    section(
                        title: "5. Free Trial",
                        body: "Droword may offer a free trial period for PRO features. The trial provides full access to PRO features for a limited time.\n\nEach user is entitled to one free trial. After the trial period expires, PRO features will be restricted unless you subscribe."
                    )
                }
                .padding(.horizontal)

                Group {
                    section(
                        title: "6. Acceptable Use",
                        body: "You agree not to:\n\n• Use the App for any unlawful purpose.\n• Attempt to reverse-engineer, decompile, or disassemble the App.\n• Circumvent any security features or access restrictions.\n• Use automated tools to access the App's services.\n• Redistribute, sublicense, or resell the App or its content."
                    )

                    section(
                        title: "7. Intellectual Property",
                        body: "The App, including its design, code, content, and branding, is the intellectual property of the developer.\n\nContent you create within the App (your words, notes, and translations) remains yours. By using the App, you grant us no rights to your personal content."
                    )

                    section(
                        title: "8. Third-Party Services",
                        body: "The App uses third-party services to provide certain features:\n\n• AI Translation (Anthropic Claude) — for generating translations and explanations.\n• Text-to-Speech (OpenAI TTS) — for word pronunciation.\n\nThese services are subject to their own terms and privacy policies. We are not responsible for the availability or accuracy of third-party services."
                    )

                    section(
                        title: "9. Disclaimer of Warranties",
                        body: "The App is provided \"as is\" and \"as available\" without warranties of any kind, whether express or implied.\n\nWe do not warrant that:\n• The App will be uninterrupted or error-free.\n• Translations or AI-generated content will be accurate.\n• The App will meet your specific requirements.\n\nYou use the App at your own risk."
                    )

                    section(
                        title: "10. Limitation of Liability",
                        body: "To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.\n\nOur total liability for any claim related to the App shall not exceed the amount you paid for the App in the 12 months preceding the claim."
                    )
                }
                .padding(.horizontal)

                Group {
                    section(
                        title: "11. Changes to Terms",
                        body: "We may update these Terms from time to time. Changes will be reflected by updating the \"Last updated\" date. Continued use of the App after changes constitutes acceptance of the updated terms."
                    )

                    section(
                        title: "12. Termination",
                        body: "We reserve the right to terminate or suspend access to the App at any time, without notice, for conduct that violates these Terms or is harmful to other users or the App."
                    )

                    section(
                        title: "13. Governing Law",
                        body: "These Terms shall be governed by and construed in accordance with applicable law, without regard to conflict of law principles."
                    )

                    section(
                        title: "14. Contact",
                        body: "If you have any questions about these Terms, please contact us via the App Store support link."
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

    private func section(title: String, body: String) -> some View {
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
