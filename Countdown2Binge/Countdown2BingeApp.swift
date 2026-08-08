//
//  Countdown2BingeApp.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 7/9/26.
//

import SwiftUI
import SwiftData
import BackgroundTasks

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
                .onAppear {
                    if !hasLaunched {
                        print("🎬 Craig's Countdown2Binge Debug Mode")
                        hasLaunched = true
                        Task {
                            await PremiumManager.shared.configure()
                            await PremiumManager.shared.loadGracePeriodState()
                            await FranchiseService.shared.fetchFranchises()
                            await seriesManager.refreshAll()
                            // 1. Restore shows from iCloud (for reinstalls)
                            await seriesManager.restoreShowsFromCloud()
                            // 2. Restore and merge watch progress from iCloud
                            await seriesManager.mergeWatchProgressWithCloud()
                            // 3. Sync all followed shows to iCloud (marks them as synced)
                            await seriesManager.syncAllShowsToCloud()
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                if hasLaunched {
                    Task { @MainActor in
                        await seriesManager.refreshAll()
                    }
                }
            case .background:
                // Schedule background refresh when app enters background
                scheduleBackgroundRefresh()
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
            print("📅 Background refresh scheduled")
        } catch BGTaskScheduler.Error.unavailable {
            print("⚠️ Background refresh unavailable on this device")
        } catch BGTaskScheduler.Error.tooManyPendingTaskRequests {
            print("⚠️ Too many pending background tasks")
        } catch {
            print("⚠️ Could not schedule background refresh: \(error)")
        }
    }

    /// Perform background refresh — reuses the tested foreground path.
    /// Calling a @MainActor async function automatically hops to the main actor.
    private func performBackgroundRefresh() async {
        print("🌙 Background refresh starting")

        // refreshAll is @MainActor async — Swift automatically hops actors on the call
        await seriesManager.refreshAll(force: false)

        print("🌙 Background refresh completed")
    }
}
