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

    // MARK: - TestFlight Detection

    /// Returns true if the app is running from TestFlight (sandbox receipt)
    static var isTestFlight: Bool {
        #if DEBUG
        return false // Not TestFlight in debug builds
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

    #if DEBUG
    private static let debugPremiumKey = "PremiumManager.debugPremiumOverride"

    /// Debug override to simulate premium status (DEBUG builds only)
    /// Persisted to UserDefaults so it survives app relaunch
    var debugPremiumOverride: Bool = UserDefaults.standard.bool(forKey: debugPremiumKey) {
        didSet {
            UserDefaults.standard.set(debugPremiumOverride, forKey: Self.debugPremiumKey)
            if debugPremiumOverride {
                isPremium = true
                didDowngradeFromPremium = false
                print("PremiumManager: DEBUG - Premium enabled via override")
            } else {
                // When toggled off, simulate downgrade
                let wasPremium = isPremium
                isPremium = false
                if wasPremium {
                    didDowngradeFromPremium = true
                    print("PremiumManager: DEBUG - Simulated downgrade from premium")
                }
                print("PremiumManager: DEBUG - Premium disabled, checking real entitlements...")
                Task {
                    await checkEntitlements()
                }
            }
        }
    }
    #endif

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
        #if DEBUG
        // Auto-enable premium for DEBUG builds (simulator)
        isPremium = true
        print("PremiumManager: DEBUG build - Premium auto-enabled")
        #endif

        // Auto-enable premium for TestFlight builds
        if Self.isTestFlight {
            isPremium = true
            isBetaTester = true
            print("PremiumManager: TestFlight build detected - Premium auto-enabled")
        }
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
            print("PremiumManager: RevenueCat API key not configured")
            return
        }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: apiKey)
        await checkEntitlements()
    }

    // MARK: - Entitlement Checking

    /// Check current entitlements and update state
    func checkEntitlements() async {
        #if DEBUG
        // Skip entitlement check for DEBUG builds - always premium
        return
        #else
        // Skip entitlement check for TestFlight - premium is always enabled
        if Self.isTestFlight {
            return
        }

        let apiKey = Self.apiKey
        guard !apiKey.isEmpty else { return }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateState(from: customerInfo)
        } catch {
            print("PremiumManager: Failed to check entitlements - \(error)")
        }
        #endif
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
                print("PremiumManager: Grace period cleared - user re-subscribed")
            }
        }

        // Detect downgrade from premium to free
        if wasPremium && !isPremium {
            didDowngradeFromPremium = true
            print("PremiumManager: Detected downgrade from premium to free")
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
        try await Purchases.shared.offerings()
    }

    // MARK: - Purchase

    /// Purchase a package
    /// - Parameter package: The package to purchase
    /// - Returns: `true` if purchase completed, `false` if user cancelled
    func purchase(package: Package) async throws -> Bool {
        print("PremiumManager: Starting purchase for \(package.identifier)")
        do {
            let result = try await Purchases.shared.purchase(package: package)
            print("PremiumManager: Purchase result - userCancelled: \(result.userCancelled)")

            if result.userCancelled {
                print("PremiumManager: User cancelled purchase")
                return false
            }

            updateState(from: result.customerInfo)
            print("PremiumManager: Purchase successful! isPremium: \(isPremium)")
            return true
        } catch {
            print("PremiumManager: Purchase failed - \(error)")
            throw error
        }
    }

    // MARK: - Restore

    /// Restore previous purchases
    func restorePurchases() async throws {
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

        print("PremiumManager: Started 3-day grace period (expires: \(expiry), shows: \(showCount))")

        // Persist to CloudKit
        do {
            try await CloudKitManager.shared.saveUserSettings(
                gracePeriodExpiry: expiry,
                gracePeriodStartedAt: now,
                premiumShowCount: showCount
            )
        } catch {
            print("PremiumManager: Failed to save grace period to CloudKit - \(error)")
        }
    }

    /// Clear grace period (user re-subscribed or completed show selection)
    func clearGracePeriod() async {
        gracePeriodExpiry = nil
        gracePeriodStartedAt = nil
        gracePeriodShowCount = 0
        isInGracePeriod = false
        didDowngradeFromPremium = false

        print("PremiumManager: Cleared grace period")

        // Clear from CloudKit
        do {
            try await CloudKitManager.shared.clearGracePeriod()
        } catch {
            print("PremiumManager: Failed to clear grace period from CloudKit - \(error)")
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
                    print("PremiumManager: Loaded active grace period (expires: \(expiry))")
                } else {
                    // Grace period expired - keep data but mark as expired
                    // ContentView will show the removal modal
                    isInGracePeriod = true
                    print("PremiumManager: Loaded expired grace period")
                }
            }
        } catch {
            print("PremiumManager: Failed to load grace period state - \(error)")
        }
    }
}
