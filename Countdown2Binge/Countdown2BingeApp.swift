//
//  Countdown2BingeApp.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 1/11/26.
//

import SwiftUI
import SwiftData

// MARK: - App Delegate for Orientation Support

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return OrientationManager.shared.orientation
    }
}

@main
struct Countdown2BingeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    let modelContainer: ModelContainer
    let backgroundTaskService: BackgroundTaskService?
    let stateRefreshService: StateRefreshService?

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
        ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
        NSClassFromString("XCTestCase") != nil
    }

    init() {
        // Initialize SwiftData
        let schema = Schema([
            FollowedShow.self,
            CachedShowData.self,
        ])

        // Use in-memory storage for tests
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: Self.isRunningTests,
            cloudKitDatabase: .none // iCloud backup will be added in Phase 9
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Skip services during tests
        if Self.isRunningTests {
            backgroundTaskService = nil
            stateRefreshService = nil
        } else {
            backgroundTaskService = BackgroundTaskService(modelContainer: modelContainer)
            backgroundTaskService?.registerBackgroundTasks()
            stateRefreshService = StateRefreshService(modelContainer: modelContainer)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Refresh shows on app launch
                    await stateRefreshService?.onAppLaunch()
                    // Schedule background refresh
                    backgroundTaskService?.scheduleShowRefresh()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active && oldPhase == .background {
                        // App came to foreground - refresh states
                        Task {
                            await stateRefreshService?.onAppForeground()
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
