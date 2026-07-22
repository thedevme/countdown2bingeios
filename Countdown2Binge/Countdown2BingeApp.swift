//
//  Countdown2BingeApp.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 7/9/26.
//

import SwiftUI
import SwiftData

@main
struct Countdown2BingeApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var hasLaunched = false

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FollowedShow.self,
            CachedShowData.self,
            Series.self,
            SeriesSeason.self,
            SeriesEpisode.self,
            CachedDiscoverShow.self,
            DiscoverCacheMetadata.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private var stateRefreshService: StateRefreshService {
        StateRefreshService(
            modelContainer: sharedModelContainer,
            badgeManager: TabBadgeManager.shared
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if !hasLaunched {
                        hasLaunched = true
                        Task {
                            await stateRefreshService.onAppLaunch()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // App returned to foreground
                if hasLaunched {
                    Task { @MainActor in
                        await stateRefreshService.onAppForeground()
                    }
                }
            case .inactive, .background:
                // App going to background - could schedule background tasks here
                break
            @unknown default:
                break
            }
        }
    }
}
