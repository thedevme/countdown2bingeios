//
//  PremiumManager.swift
//  Countdown2Binge
//

import Foundation
import RevenueCat

/// Manages premium subscription state and RevenueCat integration
@MainActor
@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    /// Live entitlement feed from RevenueCat. Held so it can be cancelled and
    /// restarted, and so it isn't torn down by ARC.
    private var customerInfoTask: Task<Void, Never>?

    /// Purchases.configure() has run. RevenueCat traps if `Purchases.shared` is
    /// touched before that, so every entry point goes through
    /// `ensureConfigured()` rather than assuming launch got there first.
    private var isConfigured = false

    // MARK: - TestFlight Detection

    /// True when the build carries a sandbox receipt.
    ///
    /// ⚠️ This does NOT mean "TestFlight". App Review builds carry a sandbox
    /// receipt as well, and so does any build a reviewer runs. There is no API
    /// that separates the two — both are sandbox. Treat this as "not the App
    /// Store production environment", nothing more. NEVER grant entitlements
    /// from it — premium comes from RevenueCat and nowhere else.
    static var hasSandboxReceipt: Bool {
        #if DEBUG
        return false
        #else
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
        #endif
    }

    // MARK: - State

    /// Whether the user has an active premium subscription
    private(set) var isPremium: Bool = false

    /// Whether user is a registered beta tester
    private(set) var isBetaTester: Bool = false

    /// Whether the user is currently in a trial period
    private(set) var isInTrial: Bool = false

    /// Trial expiration date (if in trial)
    private(set) var trialExpirationDate: Date? = nil

    /// Tracks when user downgrades from premium to free (for showing removal modal)
    var didDowngradeFromPremium: Bool = false

    // MARK: - Grace Period State

    /// Whether user is currently in a grace period after downgrading
    private(set) var isInGracePeriod: Bool = false

    /// When the grace period expires
    private(set) var gracePeriodExpiry: Date? = nil

    /// When the grace period started
    private(set) var gracePeriodStartedAt: Date? = nil

    /// Number of shows when grace period started
    private(set) var gracePeriodShowCount: Int = 0

    /// Days remaining in trial
    var trialDaysRemaining: Int? {
        guard let expirationDate = trialExpirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
        return max(0, days ?? 0)
    }

    /// Days remaining in grace period
    var gracePeriodDaysRemaining: Int? {
        guard let expiry = gracePeriodExpiry else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day
        return max(0, days ?? 0)
    }

    /// Whether the grace period has expired
    var isGracePeriodExpired: Bool {
        guard let expiry = gracePeriodExpiry else { return false }
        return Date() >= expiry
    }

    // MARK: - Computed Properties

    /// Maximum number of shows allowed
    var showLimit: Int {
        isPremium ? .max : 3
    }

    /// Whether notifications feature is available
    var canUseNotifications: Bool {
        isPremium
    }

    /// Whether cloud sync is available (disabled during grace period)
    var canUseCloudSync: Bool {
        if isInGracePeriod { return false }
        return isPremium
    }

    /// Whether spinoff collections are available
    var canViewSpinoffs: Bool {
        isPremium
    }

    // MARK: - Initialization

    private init() {
        // Informational only. Premium is NEVER granted from the receipt type:
        // App Review runs on a sandbox receipt just like TestFlight, so doing
        // that handed reviewers a fully unlocked app and they never saw the
        // free tier or a working paywall.
        isBetaTester = Self.hasSandboxReceipt
    }

    // MARK: - Show Limit

    /// Check if user can add another show
    /// - Parameter currentCount: Current number of followed shows
    /// - Returns: `true` if user can add more shows
    func canAddShow(currentCount: Int) -> Bool {
        // Block adding shows during grace period
        if isInGracePeriod { return false }
        return currentCount < showLimit
    }

    // MARK: - RevenueCat Configuration

    /// RevenueCat API key loaded from Config.plist
    private static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["REVENUECAT_API_KEY"] as? String,
              key != "YOUR_REVENUECAT_API_KEY_HERE" else {
            return ""
        }
        return key
    }

    /// Configure RevenueCat SDK - call on app launch
    func configure() async {
        let apiKey = Self.apiKey
        guard !apiKey.isEmpty else {
            return
        }

        guard !isConfigured else { return }

        // Silence RevenueCat's own logger. It defaults to verbose and prints a
        // wall of "DEBUG: ..." — every API request, cache decision and product
        // fetch — which is not ours and does not go away by deleting our own
        // print calls. `.error` still surfaces real failures.
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true

        await checkEntitlements()
        startListeningForEntitlementChanges()

    }

    // MARK: - Entitlement Checking

    /// Check current entitlements and update state
    func checkEntitlements() async {
        let apiKey = Self.apiKey
        guard !apiKey.isEmpty else { return }
        guard isConfigured else { return }   // configure() calls us right after it sets this

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateState(from: customerInfo)
        } catch {
        }
    }

    /// Configure on demand. Safe to call from anywhere, any number of times —
    /// removes the ordering dependency between app launch and the paywall.
    private func ensureConfigured() async {
        guard !isConfigured else { return }
        await configure()
    }

    /// Apply entitlement changes as RevenueCat reports them.
    ///
    /// Without this, `isPremium` was only ever computed at launch: a trial that
    /// expired, a cancellation, a refund, or a purchase made on another device
    /// wouldn't register until the user force-quit and relaunched — so someone
    /// could keep premium they no longer had, or pay and not receive it.
    ///
    /// `customerInfoStream` yields the current value immediately and then every
    /// subsequent change, including renewals and expiries.
    private func startListeningForEntitlementChanges() {
        customerInfoTask?.cancel()
        customerInfoTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard let self else { return }
                self.updateState(from: info)
            }
        }
    }

    /// Re-ask RevenueCat for the truth. Call when the app returns to the
    /// foreground: a subscription can lapse while the app is backgrounded, and
    /// the stream may not have been running to catch it.
    func refreshEntitlements() async {
        await checkEntitlements()
    }

    /// Update internal state from CustomerInfo
    private func updateState(from customerInfo: CustomerInfo) {
        let wasPremium = isPremium
        let premiumEntitlement = customerInfo.entitlements["premium"]
        isPremium = premiumEntitlement?.isActive == true

        // Handle re-subscription during grace period
        if isPremium && isInGracePeriod {
            Task {
                await clearGracePeriod()
            }
        }

        // Detect downgrade from premium to free
        if wasPremium && !isPremium {
            didDowngradeFromPremium = true
        }

        // Check trial status
        if let entitlement = premiumEntitlement,
           entitlement.isActive,
           entitlement.periodType == .trial {
            isInTrial = true
            trialExpirationDate = entitlement.expirationDate
        } else {
            isInTrial = false
            trialExpirationDate = nil
        }
    }

    // MARK: - Offerings

    /// Fetch available offerings from RevenueCat
    /// - Returns: Available offerings
    func getOfferings() async throws -> Offerings {
        await ensureConfigured()
        return try await Purchases.shared.offerings()
    }

    // MARK: - Purchase

    /// Purchase a package
    /// - Parameter package: The package to purchase
    /// - Returns: `true` if purchase completed, `false` if user cancelled
    func purchase(package: Package) async throws -> Bool {
        await ensureConfigured()
        do {
            let result = try await Purchases.shared.purchase(package: package)

            if result.userCancelled {
                return false
            }

            updateState(from: result.customerInfo)
            return true
        } catch {
            throw error
        }
    }

    // MARK: - Restore

    /// Restore previous purchases
    func restorePurchases() async throws {
        await ensureConfigured()
        let customerInfo = try await Purchases.shared.restorePurchases()
        updateState(from: customerInfo)
    }

    // MARK: - Grace Period

    /// Start a 3-day grace period when user downgrades with more than 3 shows
    /// - Parameter showCount: Number of shows at time of downgrade
    func startGracePeriod(showCount: Int) async {
        let now = Date()
        let expiry = Calendar.current.date(byAdding: .day, value: 3, to: now)!

        gracePeriodExpiry = expiry
        gracePeriodStartedAt = now
        gracePeriodShowCount = showCount
        isInGracePeriod = true


        // Persist to CloudKit
        do {
            try await CloudKitManager.shared.saveUserSettings(
                gracePeriodExpiry: expiry,
                gracePeriodStartedAt: now,
                premiumShowCount: showCount
            )
        } catch {
        }
    }

    /// Clear grace period (user re-subscribed or completed show selection)
    func clearGracePeriod() async {
        gracePeriodExpiry = nil
        gracePeriodStartedAt = nil
        gracePeriodShowCount = 0
        isInGracePeriod = false
        didDowngradeFromPremium = false


        // Clear from CloudKit
        do {
            try await CloudKitManager.shared.clearGracePeriod()
        } catch {
        }
    }

    /// Load grace period state from CloudKit (call on app launch)
    func loadGracePeriodState() async {
        do {
            let settings = try await CloudKitManager.shared.fetchUserSettings()

            if let expiry = settings.gracePeriodExpiry {
                gracePeriodExpiry = expiry
                gracePeriodStartedAt = settings.gracePeriodStartedAt
                gracePeriodShowCount = settings.premiumShowCount ?? 0

                // Check if still active or expired
                if Date() < expiry {
                    isInGracePeriod = true
                } else {
                    // Grace period expired - keep data but mark as expired
                    // ContentView will show the removal modal
                    isInGracePeriod = true
                }
            }
        } catch {
        }
    }
}
