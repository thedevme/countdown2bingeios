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
            _seriesManager = State(initialValue: SeriesManager(context: container.mainContext))
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
            case .inactive, .background:
                break
            @unknown default:
                break
            }
        }
    }
}
