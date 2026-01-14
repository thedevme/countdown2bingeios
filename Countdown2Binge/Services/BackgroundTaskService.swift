//
//  BackgroundTaskService.swift
//  Countdown2Binge
//

import Foundation
import BackgroundTasks
import SwiftData

/// Background task identifiers
enum BackgroundTaskIdentifier {
    static let showRefresh = "io.countdown2binge.showRefresh"
}

/// Service for managing background refresh of show data
final class BackgroundTaskService {
    private let tmdbService: TMDBServiceProtocol
    private let modelContainer: ModelContainer

    init(tmdbService: TMDBServiceProtocol = TMDBService(), modelContainer: ModelContainer) {
        self.tmdbService = tmdbService
        self.modelContainer = modelContainer
    }

    // MARK: - Registration

    /// Register background tasks with the system. Call from app launch.
    func registerBackgroundTasks() {
        // Skip registration during tests or if already registered
        guard !isRunningTests else { return }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.showRefresh,
            using: nil
        ) { [weak self] task in
            self?.handleShowRefresh(task: task as! BGAppRefreshTask)
        }
    }

    /// Schedule the next background refresh
    func scheduleShowRefresh() {
        // Skip scheduling during tests
        guard !isRunningTests else { return }

        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskIdentifier.showRefresh)
        // Request refresh no earlier than 1 hour from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }

    /// Check if running in a test environment
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    // MARK: - Task Handling

    private func handleShowRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleShowRefresh()

        // Create a task to refresh shows
        let refreshTask = Task {
            await refreshStaleShows()
        }

        // Handle expiration
        task.expirationHandler = {
            refreshTask.cancel()
        }

        // Complete when done
        Task {
            _ = await refreshTask.result
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Refresh Logic

    /// Refresh all stale shows from TMDB
    @MainActor
    func refreshStaleShows() async {
        let context = modelContainer.mainContext
        let store = FollowedShowsStore(modelContext: context)

        do {
            let staleShows = try store.getShowsNeedingRefresh()

            for followedShow in staleShows {
                do {
                    let show = try await tmdbService.getShowDetails(id: followedShow.tmdbId)
                    try store.updateCache(for: followedShow.tmdbId, with: show)
                } catch {
                    // Log but continue with other shows
                    print("Failed to refresh show \(followedShow.tmdbId): \(error)")
                }
            }
        } catch {
            print("Failed to get stale shows: \(error)")
        }
    }

    /// Refresh a single show (called when following or manually)
    @MainActor
    func refreshShow(id: Int) async throws {
        let context = modelContainer.mainContext
        let store = FollowedShowsStore(modelContext: context)

        let show = try await tmdbService.getShowDetails(id: id)
        try store.updateCache(for: id, with: show)
    }
}
