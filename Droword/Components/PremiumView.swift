import SwiftUI

struct PremiumView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPremium") private var isPremium: Bool = false

    /// When shown as a premium wall (fullScreenCover), show X button
    var asWall: Bool = false

    // Gold palette
    private let goldLight = Color(hex: "#FFD84D")
    private let goldMain = Color(hex: "#F5C518")
    private let goldDark = Color(hex: "#C9A200")
    private let darkCard = Color.white.opacity(0.07)
    private let darkCardBorder = Color.white.opacity(0.10)

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    private var features: [Feature] {[
        Feature(icon: "text.bubble.fill", color: Color(hex: "#5DC8F7"), title: "AI Translation", subtitle: "Claude AI with context & examples"),
        Feature(icon: "speaker.wave.2.fill", color: Color(hex: "#B57BFF"), title: "Voice Pronunciation", subtitle: "Natural ChatGPT voices"),
        Feature(icon: "lightbulb.fill", color: goldMain, title: "Word Suggestions", subtitle: "AI-powered topic suggestions"),
        Feature(icon: "paintpalette.fill", color: Color(hex: "#FF6B9D"), title: "Themes & Cosmetics", subtitle: "Exclusive visual customization"),
        Feature(icon: "sparkles", color: Color(hex: "#4CD964"), title: "Seasonal Effects", subtitle: "Animated decorations"),
    ]}

    @State private var visibleFeatures: Int = 0
    @State private var crownScale: CGFloat = 0.5
    @State private var crownOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.9
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Dark background
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    featuresSection
                    if !isPremium {
                        freePlanSection
                    }
                    ctaSection
                }
                .padding(.bottom, 50)
            }

            // Close button (wall mode)
            if asWall {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(10)
                        .background(Color.white.opacity(0.1))
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
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: asWall ? 56 : 32)

            // Crown with shimmer
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [goldMain.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(goldMain)
                    .shimmering(active: true, speed: 2.5, blendMode: .screen, opacity: 1.0)
            }
            .scaleEffect(crownScale)
            .opacity(crownOpacity)

            // Title
            VStack(spacing: 6) {
                Text("Droword PRO")
                    .font(.custom("Poppins-Bold", size: 30))
                    .foregroundColor(.white)

                Text(isPremium ? "You have full access" : "Unlimited AI power")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            .offset(y: titleOffset)
            .opacity(titleOpacity)

            // AI explanation (non-premium)
            if !isPremium {
                Text("Every request uses Claude AI and ChatGPT — real models that cost money. Premium keeps the app running.")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                featureRow(feature: feature, index: index)
                    .opacity(index < visibleFeatures ? 1 : 0)
                    .offset(y: index < visibleFeatures ? 0 : 16)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.06), value: visibleFeatures)
            }
        }
        .padding(.horizontal, 20)
    }

    private func featureRow(feature: Feature, index: Int) -> some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: feature.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(feature.title)
                        .font(.custom("Poppins-Medium", size: 15))
                        .foregroundColor(.white)

                    if !isPremium {
                        Text("Unlimited")
                            .font(.custom("Poppins-Bold", size: 9))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(goldMain))
                    }
                }
                Text(feature.subtitle)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            if isPremium {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(goldMain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(darkCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(darkCardBorder, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Free Plan

    private var freePlanSection: some View {
        VStack(spacing: 8) {
            Text("Free plan")
                .font(.custom("Poppins-Medium", size: 13))
                .foregroundColor(.white.opacity(0.4))

            HStack(spacing: 16) {
                freeStat(value: "3", label: "translations")
                freeDot()
                freeStat(value: "10", label: "voice plays")
                freeDot()
                freeStat(value: "4", label: "suggestions")
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func freeStat(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundColor(.white.opacity(0.6))
            Text(label)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    private func freeDot() -> some View {
        Circle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 4, height: 4)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 14) {
            if isPremium {
                // Active state
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(goldMain)
                    Text("PRO is active")
                        .font(.custom("Poppins-Bold", size: 17))
                        .foregroundColor(goldMain)
                }
                .padding(.top, 32)
            } else {
                // Upgrade button
                Button {
                    // TODO: StoreKit purchase
                } label: {
                    Text("Upgrade to PRO")
                        .font(.custom("Poppins-Bold", size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [goldLight, goldMain],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shimmering(active: true, speed: 2.0, blendMode: .screen, opacity: 1.0)
                }
                .buttonStyle(Duo3DButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)

                Button {
                    // TODO: Restore purchases
                } label: {
                    Text("Restore purchases")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
        }
    }

    // MARK: - Animations

    private func animateEntrance() {
        // Crown
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            crownScale = 1.0
            crownOpacity = 1.0
        }

        // Title
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        // Features stagger
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            visibleFeatures = features.count
        }

        // CTA button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
            buttonScale = 1.0
            buttonOpacity = 1.0
        }
    }
}
