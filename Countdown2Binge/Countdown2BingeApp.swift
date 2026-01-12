//
//  Countdown2BingeApp.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 1/11/26.
//

import SwiftUI
import SwiftData

@main
struct Countdown2BingeApp: App {
    let modelContainer: ModelContainer
    let backgroundTaskService: BackgroundTaskService?

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

        // Skip background task service during tests
        if Self.isRunningTests {
            backgroundTaskService = nil
        } else {
            backgroundTaskService = BackgroundTaskService(modelContainer: modelContainer)
            backgroundTaskService?.registerBackgroundTasks()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Schedule background refresh when app launches (not during tests)
                    backgroundTaskService?.scheduleShowRefresh()
                }
        }
        .modelContainer(modelContainer)
    }
}
