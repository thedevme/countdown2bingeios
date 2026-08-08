//
//  PaywallView.swift
//  Countdown2Binge
//
//  Premium paywall screen shown during onboarding and in Settings for free users.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Binding var selectedPlan: String
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?
    @State private var isLoadingOfferings: Bool = true
    @State private var offerings: Offerings?

    let onDismiss: () -> Void
    let onContinueFree: (() -> Void)?

    /// Whether to show the "Continue with Free" option (onboarding) or just X to close (settings)
    var showContinueFree: Bool = true

    /// Package identifiers mapped to plan IDs
    private let packageIds: [String: String] = [
        "monthly": "$rc_monthly",
        "yearly": "$rc_annual",
        "lifetime": "$rc_lifetime"
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with posters
                    PaywallHeader()

                    // Title section
                    VStack(spacing: 8) {
                        Text("COUNTDOWN2BINGE PREMIUM")
                            .font(.custom(.jetbrains.bold, size: 11))
                            .foregroundColor(.c2bTeal)
                            .tracking(1.5)

                        VStack(spacing: 0) {
                            Text("TRACK EVERYTHING.")
                                .font(.custom(.oswald.bold, size: 32))
                                .foregroundColor(.white)
                            Text("MISS NOTHING.")
                                .font(.custom(.oswald.bold, size: 32))
                                .foregroundColor(.c2bTeal)
                        }

                        Text("Unlimited shows, alerts the day a season lands, and your whole lineup synced everywhere.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.c2bMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                    }
                    .padding(.top, 16)

                    // Plan selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE YOUR PLAN")
                            .font(.custom(.jetbrains.bold, size: 10))
                            .foregroundColor(.c2bMuted)
                            .tracking(1.2)
                            .padding(.top, 24)
                            .padding(.bottom, 4)

                        if isLoadingOfferings {
                            // Loading state
                            ForEach(["monthly", "yearly", "lifetime"], id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.03))
                                    .frame(height: 72)
                                    .overlay(
                                        ProgressView()
                                            .tint(.c2bMuted)
                                    )
                            }
                        } else {
                            // Monthly
                            if let monthlyPackage = getPackage(for: "monthly") {
                                PlanCard(
                                    id: "monthly",
                                    name: "MONTHLY",
                                    price: monthlyPackage.localizedPriceString,
                                    period: "/mo",
                                    subtitle: "CANCEL ANYTIME",
                                    badge: nil,
                                    isSelected: selectedPlan == "monthly",
                                    onSelect: { selectedPlan = "monthly" }
                                )
                            }

                            // Yearly
                            if let yearlyPackage = getPackage(for: "yearly") {
                                let monthlyEquivalent = calculateMonthlyPrice(from: yearlyPackage)
                                PlanCard(
                                    id: "yearly",
                                    name: "YEARLY",
                                    price: yearlyPackage.localizedPriceString,
                                    period: "/yr",
                                    subtitle: "7-DAY FREE TRIAL · \(monthlyEquivalent)/MO",
                                    badge: calculateSavingsBadge(),
                                    isSelected: selectedPlan == "yearly",
                                    onSelect: { selectedPlan = "yearly" }
                                )
                            }

                            // Lifetime
                            if let lifetimePackage = getPackage(for: "lifetime") {
                                PlanCard(
                                    id: "lifetime",
                                    name: "LIFETIME",
                                    price: lifetimePackage.localizedPriceString,
                                    period: "once",
                                    subtitle: "PAY ONCE, KEEP FOREVER",
                                    badge: nil,
                                    isSelected: selectedPlan == "lifetime",
                                    onSelect: { selectedPlan = "lifetime" }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // CTA Button
                    Button(action: handlePurchase) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.c2bBackground)
                        } else {
                            Text(ctaButtonText)
                                .font(.custom(.oswald.bold, size: 16))
                                .tracking(0.5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.c2bTeal)
                    .foregroundColor(.c2bBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .disabled(isPurchasing)

                    // Trial info text
                    Text(trialInfoText)
                        .font(.custom(.jetbrains.regular, size: 10))
                        .foregroundColor(.c2bMuted)
                        .tracking(0.5)
                        .padding(.top, 8)

                    // Free includes section
                    FreeIncludesSection()
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    // Premium unlocks section
                    PremiumUnlocksSection()
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    // Second CTA Button
                    Button(action: handlePurchase) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.c2bBackground)
                        } else {
                            Text(ctaButtonText)
                                .font(.custom(.oswald.bold, size: 16))
                                .tracking(0.5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.c2bTeal)
                    .foregroundColor(.c2bBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .disabled(isPurchasing)

                    // Trial info text
                    Text(trialInfoText)
                        .font(.custom(.jetbrains.regular, size: 10))
                        .foregroundColor(.c2bMuted)
                        .tracking(0.5)
                        .padding(.top, 8)

                    // Footer links
                    HStack(spacing: 16) {
                        Button("RESTORE") { handleRestore() }
                        Text("·").foregroundColor(.c2bMuted)
                        Button("TERMS") { }
                        Text("·").foregroundColor(.c2bMuted)
                        Button("PRIVACY") { }
                    }
                    .font(.custom(.jetbrains.regular, size: 10))
                    .foregroundColor(.c2bMuted)
                    .tracking(0.5)
                    .padding(.top, 16)

                    // Continue with free option
                    if showContinueFree {
                        Button(action: { onContinueFree?() ?? onDismiss() }) {
                            Text("CONTINUE WITH FREE · 3 SHOWS")
                                .font(.custom(.jetbrains.bold, size: 12))
                                .foregroundColor(.c2bTeal)
                                .tracking(0.5)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    } else {
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .background(Color.c2bBackground)

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.c2bMuted)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .task {
            await loadOfferings()
        }
    }

    // MARK: - Computed Properties

    private var ctaButtonText: String {
        switch selectedPlan {
        case "yearly":
            return "START 7-DAY FREE TRIAL"
        case "lifetime":
            return "PURCHASE LIFETIME"
        default:
            return "SUBSCRIBE NOW"
        }
    }

    private var trialInfoText: String {
        switch selectedPlan {
        case "yearly":
            if let package = getPackage(for: "yearly") {
                return "FREE FOR 7 DAYS, THEN \(package.localizedPriceString)/YR · CANCEL ANYTIME"
            }
            return "FREE FOR 7 DAYS · CANCEL ANYTIME"
        case "monthly":
            if let package = getPackage(for: "monthly") {
                return "\(package.localizedPriceString)/MONTH · CANCEL ANYTIME"
            }
            return "CANCEL ANYTIME"
        case "lifetime":
            return "ONE-TIME PURCHASE · NEVER EXPIRES"
        default:
            return ""
        }
    }

    // MARK: - Actions

    private func handlePurchase() {
        Task {
            guard let package = getPackage(for: selectedPlan) else {
                purchaseError = "Package not found"
                return
            }

            isPurchasing = true
            defer { isPurchasing = false }

            do {
                let success = try await PremiumManager.shared.purchase(package: package)
                if success {
                    onDismiss()
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    private func handleRestore() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                try await PremiumManager.shared.restorePurchases()
                if PremiumManager.shared.isPremium {
                    onDismiss()
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    // MARK: - RevenueCat Helpers

    private func loadOfferings() async {
        do {
            offerings = try await PremiumManager.shared.getOfferings()
        } catch {
            purchaseError = "Failed to load pricing"
        }
        isLoadingOfferings = false
    }

    private func getPackage(for planId: String) -> Package? {
        guard let packageId = packageIds[planId],
              let offering = offerings?.current else {
            return nil
        }
        return offering.availablePackages.first { $0.identifier == packageId }
    }

    private func calculateMonthlyPrice(from yearlyPackage: Package) -> String {
        let yearlyPrice = yearlyPackage.storeProduct.price as Decimal
        let monthlyEquivalent = yearlyPrice / 12

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyPackage.storeProduct.priceFormatter?.locale ?? .current

        return formatter.string(from: monthlyEquivalent as NSDecimalNumber) ?? ""
    }

    private func calculateSavingsBadge() -> String? {
        guard let monthlyPackage = getPackage(for: "monthly"),
              let yearlyPackage = getPackage(for: "yearly") else {
            return nil
        }

        let monthlyPrice = monthlyPackage.storeProduct.price as Decimal
        let yearlyPrice = yearlyPackage.storeProduct.price as Decimal
        let yearlyMonthly = yearlyPrice / 12

        let savings = ((monthlyPrice - yearlyMonthly) / monthlyPrice) * 100
        let savingsInt = Int(truncating: savings as NSDecimalNumber)

        return savingsInt > 0 ? "SAVE \(savingsInt)%" : nil
    }
}

// MARK: - Paywall Header (Show Posters)

private struct PaywallHeader: View {
    // Show posters from asset library
    private let posterImages = ["fallout", "the-last-of-us", "stranger-things", "severance", "squid-game"]

    var body: some View {
        ZStack {
            // Gradient background fading to content
            LinearGradient(
                colors: [Color.c2bBackground, Color.c2bBackground.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 180)

            // Poster fan stack with actual images
            HStack(spacing: -20) {
                ForEach(Array(posterImages.enumerated()), id: \.offset) { index, imageName in
                    Image(imageName)
                        .resizable()
                        .aspectRatio(2.0/3.0, contentMode: .fill)
                        .frame(width: 80, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                        .rotationEffect(.degrees(Double(index - 2) * 5))
                        .offset(y: abs(Double(index - 2)) * 10)
                }
            }
            .padding(.top, 20)
        }
        .frame(height: 160)
    }
}

#Preview {
    PaywallView(
        selectedPlan: .constant("yearly"),
        onDismiss: {},
        onContinueFree: {}
    )
}
