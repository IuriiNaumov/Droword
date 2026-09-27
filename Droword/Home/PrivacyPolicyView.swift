import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .sheetTitle()

                Text("Last updated: 24 September 2026")
                    .font(themeStore.regular(13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, -12)

                Group {
                    policySection(
                        title: "1. Who this Policy covers",
                        body: "This Privacy Policy explains how information is handled when you use the Droword application (the \"App\"). The App is operated by its developer. Questions about this Policy: hello@droword.app.\n\nIf a translation of this Policy differs from the English text, the English text prevails."
                    )

                    policySection(
                        title: "2. What stays on your device",
                        body: "Your dictionary, saved translations, examples, tags, study progress, review schedule, settings, theme, profile image, and notification schedule are stored locally on your device, including in the shared store used by the share extension and the widget.\n\nThe App does not ask you to create an account. We do not keep a copy of your dictionary on our servers."
                    )

                    policySection(
                        title: "3. What is sent when you use an online feature",
                        body: "Online features run only when you invoke them. The minimum content needed for that request is sent over HTTPS to our API, hosted on Cloudflare, and then to a processor:\n\n• Translation, explanations, examples, stories, dialogue, and word suggestions: the text you submit, together with the languages and level you selected, is sent to Anthropic to produce a response.\n• Pronunciation: the word or phrase is sent to OpenAI to generate audio.\n• Photo scan: the image you select is sent to our API and to Anthropic so that words can be read from it. We do not keep the image, or the words read from it, on our servers after the response is returned to the App.\n\nWe do not sell this information and we do not use it to build an advertising profile. We do not control how long Anthropic or OpenAI retain a request under their own terms. Do not submit information you are unwilling to send to those processors, including another person's personal data or confidential material."
                    )

                    policySection(
                        title: "4. Payments, camera, photos, and notifications",
                        body: "Purchases are processed by Apple. We do not receive your full payment-card number.\n\nCamera and photo-library access is used only when you scan words or choose a profile image. The profile image remains on your device.\n\nPractice reminders are scheduled locally on your device. They are not sent through our servers."
                    )
                }
                .padding(.horizontal)

                Group {
                    policySection(
                        title: "5. Analytics and tracking",
                        body: "The App does not include third-party analytics, advertising, or cross-app tracking SDKs. We do not collect an advertising identifier for our own use."
                    )

                    policySection(
                        title: "6. Retention and deletion",
                        body: "On-device data remains until you delete it. You may clear the dictionary in Settings → Dictionary → Clear dictionary. Uninstalling the App removes the local store, subject to any backup Apple keeps.\n\nA request to the API is processed to return a response. We do not maintain an account archive of your dictionary or of scan images, because the App has no user account."
                    )

                    policySection(
                        title: "7. Legal bases, if GDPR or UK GDPR applies",
                        body: "Where the EU or UK General Data Protection Regulation applies, sending the text or image you submit in order to produce a translation, story, dialogue, suggestion, pronunciation, or scan is necessary to perform the feature you requested. Limiting the rate of API requests, in order to protect the service from abuse, is based on our legitimate interest and does not require an account.\n\nYou can avoid a transfer by not using that feature. Because we do not hold a server-side profile of you, you exercise access and erasure by deleting data on your device. You may also write to hello@droword.app. You may lodge a complaint with your data-protection authority. These rights do not depend on this Policy waiving them."
                    )

                    policySection(
                        title: "8. Children",
                        body: "The App is not directed to children under 13, or under 16 where a higher age of digital consent applies. We do not knowingly collect personal data from children. If you believe a child has sent personal data through an online feature, contact hello@droword.app and stop using that feature on the child's behalf."
                    )

                    policySection(
                        title: "9. Security and international transfers",
                        body: "Local data is protected by the controls of your device. Requests to the API are sent over HTTPS. No method of storage or transmission is completely secure.\n\nOur API and the model providers may process a request outside your country, including in the United States. Where the law requires a transfer tool, the transfer relies on the provider's mechanism, such as standard contractual clauses. If you do not want a word or an image to leave your device, do not use the online features. The dictionary itself remains on the device."
                    )

                    policySection(
                        title: "10. Changes and contact",
                        body: "We may update this Policy. The date above will change. If a change materially reduces your rights, the updated Policy will be presented in the App. If you continue to use the App after the effective date, you accept the updated Policy, except where the law requires a different form of consent.\n\nPrivacy questions: hello@droword.app"
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

    private func policySection(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(themeStore.bold(18))
                .foregroundStyle(.primary)
            Text(body)
                .font(themeStore.regular(14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous).fill(themeStore.cardBg))
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
    .environmentObject(ThemeStore())
}
