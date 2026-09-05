//
//  Countdown2BingeApp.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 7/9/26.
//

import SwiftUI
import SwiftData
import BackgroundTasks
import StoreKit
import TikTokOpenSDKCore

@main
struct Countdown2BingeApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var hasLaunched = false
    @State private var seriesManager: SeriesManager

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Series.self,
            Season.self,
            Episode.self,
            CachedDiscoverShow.self,
            DiscoverCacheMetadata.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContainer = container
            _seriesManager = State(initialValue: SeriesManager(container: container))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(seriesManager)
                // requestReview is a SwiftUI environment action, so a service
                // can't call it — SeriesManager raises a flag and we ask here.
                .modifier(ReviewPromptModifier(seriesManager: seriesManager))
                // TikTok Share Kit calls back through the registered URL
                // scheme; the universal-link form is what a redirectURI uses.
                // Both are no-ops until TikTokConfig is filled in.
                .onOpenURL { url in
                    _ = TikTokURLHandler.handleOpenURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    _ = TikTokURLHandler.handleOpenURL(activity.webpageURL)
                }
                .onAppear {
                    if !hasLaunched {
                        hasLaunched = true
                        // Launch work, split by what actually depends on what.
                        // This used to be eight awaits in a single chain, so
                        // the last one waited on RevenueCat, a JSON load, every
                        // TMDB refresh and three CloudKit round-trips in turn.
                        //
                        // Entitlements first and on their own: everything
                        // premium-gated below reads `isPremium`, and asking
                        // after the fact meant the first launch answered "free".
                        Task {
                            await PremiumManager.shared.configure()
                            await PremiumManager.shared.loadGracePeriodState()

                            // The cloud chain IS order-dependent and stays serial:
                            // a pending unfollow must be flushed before restore,
                            // or restore pulls the show straight back.
                            await seriesManager.flushPendingCloudUnfollows()
                            await seriesManager.restoreShowsFromCloud()
                            await seriesManager.mergeWatchProgressWithCloud()
                            await seriesManager.syncAllShowsToCloud()
                        }

                        // Independent of entitlements and of each other — no
                        // reason for either to sit behind the cloud chain.
                        Task {
                            await FranchiseService.shared.fetchFranchises()
                        }
                        Task {
                            await seriesManager.refreshAll()
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                Task { @MainActor in
                    // A subscription can lapse or be purchased elsewhere while
                    // we're backgrounded — re-ask rather than trust launch state.
                    await PremiumManager.shared.refreshEntitlements()
                }
                Task { @MainActor in
                    // Back in the app: drop any pending "shows added" digest,
                    // and clear the record if one was delivered while away.
                    await FollowDigest.shared.appDidBecomeActive()
                }
                if hasLaunched {
                    Task { @MainActor in
                        await seriesManager.refreshAll()
                    }
                }
            case .background:
                // Schedule background refresh when app enters background
                scheduleBackgroundRefresh()

                // Leaving the app starts the 20-minute digest clock.
                Task { @MainActor in
                    await FollowDigest.shared.appDidEnterBackground()
                }
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        // ═══════════════════════════════════════════════════════════════════
        // BACKGROUND REFRESH — iOS runs this when it decides (usage-based)
        //
        // LIMITATION: iOS controls background execution based on app usage patterns.
        // For users who rarely open the app, iOS may deprioritize or skip runs.
        // This improves coverage for regular users; it does not guarantee updates
        // for fully-dormant users. That gap is an iOS platform constraint, not a bug.
        // A future server+push solution would close it.
        // ═══════════════════════════════════════════════════════════════════
        .backgroundTask(.appRefresh("com.countdown2binge.refresh")) {
            // CRITICAL: Schedule NEXT request FIRST — or task dies after one run
            scheduleBackgroundRefresh()

            // Run the refresh pass
            await performBackgroundRefresh()
        }
    }

    // MARK: - Background Refresh

    /// Schedule the next background refresh request.
    /// Called: (1) inside the task handler (schedules NEXT), (2) on scenePhase .background (ensures FIRST).
    nonisolated private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.countdown2binge.refresh")
        // Earliest 4 hours out — iOS decides actual timing based on usage patterns
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch BGTaskScheduler.Error.unavailable {
        } catch BGTaskScheduler.Error.tooManyPendingTaskRequests {
        } catch {
        }
    }

    /// Perform background refresh — reuses the tested foreground path.
    /// Calling a @MainActor async function automatically hops to the main actor.
    private func performBackgroundRefresh() async {

        // refreshAll is @MainActor async — Swift automatically hops actors on the call
        await seriesManager.refreshAll(force: false)

    }
}


// MARK: - Review Prompt

/// Watches `SeriesManager.pendingReviewRequest` and asks for a rating when it
/// flips. The cadence itself lives in `ReviewPrompt` (5th, 10th, 15th …).
private struct ReviewPromptModifier: ViewModifier {
    let seriesManager: SeriesManager
    @Environment(\.requestReview) private var requestReview
    @State private var showConfirm = false

    func body(content: Content) -> some View {
        content
            .onChange(of: seriesManager.pendingReviewRequest) { _, pending in
                guard pending else { return }
                seriesManager.pendingReviewRequest = false
                // Let the follow's own UI (sheets, add-time prompt) settle first.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.2))
                    showConfirm = true
                }
            }
            // Our own confirm step. Apple's sheet reports nothing back, so this
            // is the only moment we can observe — tapping Rate marks the user
            // as done and no trigger ever fires again.
            .alert(String(localized: "review_prompt_title"), isPresented: $showConfirm) {
                Button(String(localized: "review_prompt_rate")) {
                    ReviewPrompt.markRated()
                    // NOT called synchronously here. Firing requestReview()
                    // in the same instant this alert is dismissing itself
                    // asks iOS to present its own system sheet before the
                    // alert's dismissal animation has settled — it silently
                    // declines rather than queuing it, so the call appeared
                    // to just do nothing. Give the dismissal a beat first.
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(600))
                        requestReview()
                    }
                }
                Button(String(localized: "review_prompt_later"), role: .cancel) { }
            } message: {
                Text(String(localized: "review_prompt_message"))
            }
    }
}
