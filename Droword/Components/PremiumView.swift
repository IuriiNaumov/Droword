import SwiftUI
import StoreKit

struct PremiumView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPremium") private var isPremium: Bool = false
    @AppStorage("hasUsedTrial") private var hasUsedTrial: Bool = false
    @AppStorage("trialStartDate") private var trialStartDate: String = ""
    @StateObject private var storeKit = StoreKitManager.shared

    /// When shown as a premium wall (fullScreenCover), show X button
    var asWall: Bool = false

    @State private var selectedPlan: Plan = .yearly
    @State private var appeared = false
    @State private var purchaseError: String?

    private var trialDaysRemaining: Int? {
        guard hasUsedTrial, !trialStartDate.isEmpty,
              let start = Self.trialDF.date(from: trialStartDate) else { return nil }
        let daysPassed = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        let remaining = 7 - daysPassed
        return remaining > 0 ? remaining : nil
    }

    private static let trialDF: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private enum Plan: String {
        case monthly, yearly
    }

    // Fallback pricing (shown while StoreKit loads)
    private var monthlyPrice: String {
        storeKit.monthlyProduct?.displayPrice ?? "$4.99"
    }
    private var yearlyPrice: String {
        storeKit.yearlyProduct?.displayPrice ?? "$39.99"
    }
    private var yearlyMonthly: String {
        if let product = storeKit.yearlyProduct {
            let monthly = product.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            return formatter.string(from: monthly as NSDecimalNumber) ?? "$3.33"
        }
        return "$3.33"
    }

    private struct FeatureRow: Identifiable {
        let id = UUID()
        let title: String
        let free: String    // what free users get
        let pro: String     // what PRO users get
    }

    private let featureRows: [FeatureRow] = [
        FeatureRow(title: "AI translations", free: "3 / day", pro: "Unlimited"),
        FeatureRow(title: "Voice pronunciation", free: "10 / day", pro: "Unlimited"),
        FeatureRow(title: "Word suggestions", free: "4 / day", pro: "Unlimited"),
        FeatureRow(title: "Themes", free: "Default only", pro: "All themes"),
        FeatureRow(title: "Seasonal effects", free: "—", pro: "All effects"),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, asWall ? 56 : 24)

                    if isPremium {
                        proActiveFeatures
                            .padding(.top, 28)

                        activeSection
                            .padding(.top, 28)
                    } else {
                        comparisonSection
                            .padding(.top, 28)

                        plansSection
                            .padding(.top, 28)

                        subscribeButton
                            .padding(.top, 24)

                        Button {
                            Task { await storeKit.restorePurchases() }
                        } label: {
                            Text("Restore purchases")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.secondary)
                        }
                        .disabled(storeKit.isLoading)
                        .padding(.top, 12)

                        subscriptionDisclosure

                        legalLinks
                    }
                }
                .padding(.bottom, 50)
                .iPadContentWidth(600)
            }

            // Close button (wall mode)
            if asWall {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !asWall {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(isPremium ? Color(hex: "#34C759") : Color.accentBlack)
                .scaleEffect(appeared ? 1.0 : 0.5)
                .opacity(appeared ? 1.0 : 0)

            Text("Droword PRO")
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.primary)

            if let days = trialDaysRemaining, isPremium {
                Text("Trial: \(days) \(days == 1 ? "day" : "days") remaining")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.orange)
            } else {
                Text(isPremium ? "You have full access" : "Unlock unlimited AI features")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Comparison table (free users)

    private var comparisonSection: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 80)
                Text("PRO")
                    .font(.custom("Poppins-Bold", size: 13))
                    .foregroundColor(Color.accentBlack)
                    .frame(width: 80)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Rows
            ForEach(featureRows) { row in
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Text(row.title)
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(row.free)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 80)

                        Text(row.pro)
                            .font(.custom("Poppins-Medium", size: 13))
                            .foregroundColor(Color.accentBlack)
                            .frame(width: 80)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                }
            }
        }
        .opacity(appeared ? 1.0 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - PRO active features (centered checkmarks)

    private var proActiveFeatures: some View {
        VStack(spacing: 14) {
            ForEach(featureRows) { row in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#34C759"))

                    Text(row.title)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(appeared ? 1.0 : 0)
    }

    // MARK: - Plans

    private var plansSection: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .yearly,
                title: "Yearly",
                price: yearlyPrice,
                detail: "\(yearlyMonthly)/mo",
                badge: "Save 33%"
            )

            planCard(
                plan: .monthly,
                title: "Monthly",
                price: monthlyPrice,
                detail: "per month",
                badge: nil
            )
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1.0 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    private func planCard(plan: Plan, title: String, price: String, detail: String, badge: String?) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedPlan = plan
            }
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .stroke(selectedPlan == plan ? Color.accentBlack : Color(.separator), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if selectedPlan == plan {
                        Circle()
                            .fill(Color.accentBlack)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundColor(.primary)

                        if let badge {
                            Text(badge)
                                .font(.custom("Poppins-Bold", size: 10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: "#34C759")))
                        }
                    }
                    Text(detail)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selectedPlan == plan ? Color.accentBlack : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await handlePurchase() }
            } label: {
                Group {
                    if storeKit.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Subscribe")
                            .font(.custom("Poppins-Bold", size: 17))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentBlack)
                )
            }
            .buttonStyle(Duo3DButtonStyle())
            .disabled(storeKit.isLoading)

            if let error = purchaseError {
                Text(error)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1.0 : 0)
    }

    // MARK: - Active

    private var activeSection: some View {
        VStack(spacing: 16) {
            // Status card
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#34C759"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PRO is active")
                            .font(.custom("Poppins-Bold", size: 17))
                            .foregroundColor(.primary)
                        Text("Unlimited access to all features")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Divider()

                // Subscription details
                VStack(spacing: 10) {
                    subscriptionDetailRow(label: "Plan", value: activePlanName)
                    subscriptionDetailRow(label: "Price", value: activePriceString)
                    subscriptionDetailRow(label: "Renews", value: nextRenewalDateString)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 20)

            // Manage subscription button
            Button {
                openSubscriptionManagement()
            } label: {
                HStack(spacing: 8) {
                    Text("Manage Subscription")
                        .font(.custom("Poppins-Medium", size: 15))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            // Fine print
            Text("Subscription renews automatically. You can cancel anytime in Settings → Apple ID → Subscriptions.")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 4)
        }
    }

    // MARK: - Purchase

    private func handlePurchase() async {
        purchaseError = nil
        let product: Product?
        switch selectedPlan {
        case .monthly: product = storeKit.monthlyProduct
        case .yearly:  product = storeKit.yearlyProduct
        }

        guard let product else {
            purchaseError = "Product not available. Check your connection."
            return
        }

        do {
            let success = try await storeKit.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func subscriptionDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.primary)
        }
    }

    private var activePlanName: String {
        if storeKit.purchasedProductIDs.contains(StoreKitManager.monthlyID) {
            return "Monthly"
        } else if storeKit.purchasedProductIDs.contains(StoreKitManager.yearlyID) {
            return "Yearly"
        }
        return "—"
    }

    private var activePriceString: String {
        if storeKit.purchasedProductIDs.contains(StoreKitManager.monthlyID),
           let product = storeKit.monthlyProduct {
            return "\(product.displayPrice) / month"
        } else if storeKit.purchasedProductIDs.contains(StoreKitManager.yearlyID),
                  let product = storeKit.yearlyProduct {
            return "\(product.displayPrice) / year"
        }
        return "—"
    }

    private var nextRenewalDateString: String {
        // Real renewal info requires Transaction.currentEntitlements;
        // show "Manage in Settings" to avoid fabricating a date.
        return "See Apple Settings"
    }

    private var subscriptionDisclosure: some View {
        Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings.")
            .font(.custom("Poppins-Regular", size: 11))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    private var legalLinks: some View {
        HStack(spacing: 4) {
            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Text("·")
            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
                    .environmentObject(themeStore)
            }
        }
        .font(.custom("Poppins-Regular", size: 12))
        .foregroundColor(.secondary)
        .padding(.top, 8)
    }

    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}
