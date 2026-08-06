//
//  CloudSyncViewModel.swift
//  Countdown2Binge
//
//  State and logic for the CloudSync view.
//  Data comes from @Query in the view; this VM handles UI state only.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class CloudSyncViewModel {
    // MARK: - UI State

    var isEditMode: Bool = false

    // MARK: - Dependencies

    private var premiumManager: PremiumManager?

    var isPremium: Bool {
        premiumManager?.isPremium ?? false
    }

    // MARK: - Configure

    func configure(premiumManager: PremiumManager) {
        self.premiumManager = premiumManager
    }

    // MARK: - Actions

    func toggleEditMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditMode.toggle()
        }
    }

    func exitEditMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditMode = false
        }
    }

    func removeFromCloud(series: Series, seriesManager: SeriesManager) {
        Task {
            await seriesManager.unsyncShowFromCloud(seriesId: series.id)
        }
    }

    func syncAllShows(seriesManager: SeriesManager) {
        Task {
            await seriesManager.syncAllShowsToCloud()
        }
    }

    func unsyncAllShows(seriesManager: SeriesManager) {
        Task {
            await seriesManager.unsyncAllShowsFromCloud()
        }
    }
}
