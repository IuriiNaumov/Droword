import SwiftUI

struct TermsOfUseView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Use")
                    .sheetTitle()

                Text("Last updated: 24 September 2026")
                    .font(themeStore.regular(13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, -12)

                Group {
                    section(
                        title: "1. Agreement",
                        body: "These Terms of Use govern your use of the Droword application (the \"App\"), operated by its developer. By downloading or using the App, you agree to these Terms and to the Privacy Policy. If you do not agree, do not use the App.\n\nIf a translation differs from the English text, the English text prevails. Mandatory consumer rights in your country of residence are not reduced by that rule."
                    )

                    section(
                        title: "2. The service",
                        body: "Droword is a personal dictionary and study tool. It provides spaced repetition, quizzes, and optional online features: translation, examples, stories, dialogue, word suggestions, pronunciation, and photo scan.\n\nText and audio produced by those features are generated automatically. They may be wrong, incomplete, or unsuitable. They are not a certified translation and they are not professional, medical, legal, or educational advice. You are responsible for how you rely on them."
                    )

                    section(
                        title: "3. Your content and your device",
                        body: "The App does not require an account. Words and notes you save remain on your device. You are responsible for the security of your device, for your own backups, and for having the right to submit anything you send to an online feature.\n\nDo not submit unlawful content, confidential information, or another person's personal data unless you have a lawful basis to do so. Except where liability cannot legally be limited, we are not liable for loss of on-device data caused by device failure, loss of the device, or uninstalling the App without a backup you control."
                    )

                    section(
                        title: "4. Licence",
                        body: "We grant you a personal, non-exclusive, non-transferable, revocable licence to use the App as made available through Apple, for your own language study.\n\nYou may not copy the App for distribution, rent it, sell it, or reverse engineer it except where a statute in your country expressly allows reverse engineering.\n\nContent you create remains yours. You grant us only the limited right to transmit the text or image you submit, to the processors named in the Privacy Policy, for the sole purpose of performing the feature you requested. That right ends when the response has been returned, apart from transient technical copies required to complete the request."
                    )
                }
                .padding(.horizontal)

                Group {
                    section(
                        title: "5. Subscriptions",
                        body: "Droword PRO is an optional auto-renewable subscription sold and billed by Apple, not by us.\n\n• Payment is charged to your Apple ID at confirmation of purchase.\n• The subscription renews automatically unless you cancel at least 24 hours before the end of the current period.\n• Your account is charged for renewal within 24 hours before the end of the current period.\n• You manage and cancel subscriptions in your Apple ID account settings.\n• If a free trial is offered, any unused portion is forfeited when you purchase a subscription, where Apple's rules so provide.\n• The price is the price displayed by the App Store at the time of purchase. Apple notifies you of a price change where the law requires it. A change applies as Apple implements it, ordinarily from the next renewal.\n• Refunds are handled by Apple under the Apple Media Services terms. A partial period is not refunded by us separately, except where the law of your country gives you a right that cannot be waived, including a withdrawal right for digital content you have not begun to use."
                    )

                    section(
                        title: "6. Free trial",
                        body: "If the App offers a free trial of PRO, the trial is limited as shown on the purchase screen, and to one trial as recorded by the App on that device. When the trial ends, PRO features stop unless a subscription is in force. We may change or end the trial offer for people who have not yet started it. Starting a trial does not by itself create a charge; a charge occurs only if you purchase or if Apple renews a subscription under its rules."
                    )

                    section(
                        title: "7. Acceptable use",
                        body: "You agree not to:\n\n• use the App for an unlawful purpose;\n• submit content you have no right to send, or use the App to infringe copyright or other rights;\n• probe, overload, or bypass rate limits or other protections of the API;\n• use automated means to extract the service, except a tool Apple provides for accessibility;\n• resell, sublicense, or redistribute the App or model output as a competing service.\n\nWe may refuse or throttle a request that appears to breach this section."
                    )

                    section(
                        title: "8. Apple and other third parties",
                        body: "These Terms are between you and the developer of the App, not between you and Apple. Apple is not responsible for the App or its content and has no obligation to provide maintenance or support. If the App fails to conform to an applicable warranty, you may notify Apple, and Apple may refund the purchase price, if any. To the maximum extent permitted by law, Apple has no other warranty obligation. Apple and its subsidiaries are third-party beneficiaries of the obligations in this section and may enforce them.\n\nApple's Licensed Application End User License Agreement also applies.\n\nAnthropic and OpenAI process the requests described in the Privacy Policy. Their terms apply to their own services. We are not responsible for their availability or for the content of a model response, except for liability that cannot legally be excluded.\n\nClaims relating to the App, including product claims and claims under consumer-protection law, are the developer’s responsibility, not Apple’s, except for Apple’s refund obligation described above. You must also comply with any third-party terms that apply to your use of the App.\n\nYou represent that you are not located in a country that is subject to a United States government embargo, and that you are not listed on any United States government list of prohibited or restricted parties.\n\nThe developer’s name and postal address for notices are the name and address shown on the App’s page in the App Store. You may also write to hello@droword.app."
                    )
                }
                .padding(.horizontal)

                Group {
                    section(
                        title: "9. Availability",
                        body: "We may change, limit, or withdraw features, including free daily limits on online features. Words already saved on your device remain on your device for as long as the App can read its local store. Online features require a network connection and may be unavailable."
                    )

                    section(
                        title: "10. Warranty disclaimer",
                        body: "To the extent permitted by law, the App is provided \"as is\" and \"as available\". We disclaim implied warranties of merchantability, fitness for a particular purpose, and non-infringement. We do not warrant that the App will be uninterrupted or error-free, or that automatically generated text or audio will be accurate.\n\nIf you are a consumer, this section does not take away rights that the law of your country does not allow us to exclude."
                    )

                    section(
                        title: "11. Limitation of liability",
                        body: "Nothing in these Terms excludes or limits liability for death or personal injury caused by negligence, for fraud or fraudulent misrepresentation, or for any other liability that cannot be excluded under the law of your country.\n\nSubject to the previous sentence, we are not liable for indirect or consequential loss, loss of profits, or loss of data, and our total liability arising out of the App in any twelve-month period is limited to the amount you paid through Apple for the App during that period. If you paid nothing, the limit is fifty (50) US dollars.\n\nIf you are a consumer in a country that does not allow this cap, the cap applies only as far as that law allows, and your statutory rights remain."
                    )

                    section(
                        title: "12. Changes, ending use, and contact",
                        body: "We may update these Terms by changing the date in the App. If a change is material, it will be presented in the App. Continued use after the effective date is acceptance, except where the law requires express consent.\n\nYou may stop using the App at any time by deleting it. We may suspend online features if you materially breach these Terms. Data stored only on your device remains there until you delete it.\n\nIf you use the App as a consumer, mandatory protections of the country where you live still apply. Otherwise, questions of interpretation that are not settled by those protections follow the law that applies to the developer, excluding conflict-of-law rules that would point elsewhere.\n\nQuestions about these Terms: hello@droword.app"
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

    private func section(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
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
        TermsOfUseView()
    }
    .environmentObject(ThemeStore())
}
