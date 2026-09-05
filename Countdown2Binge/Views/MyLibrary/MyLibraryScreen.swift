//
//  MyLibraryScreen.swift
//  Countdown2Binge
//
//  Top-level "My Library" tab — every followed show, one place. This is
//  the same screen that used to be Settings' Cloud Sync sub-screen
//  (reused, not rebuilt): free users get a plain, view-only list of
//  what's tracked on this device; Premium adds the iCloud status card and
//  edit/remove.
//

import SwiftUI
import SwiftData

struct MyLibraryScreen: View {
    @Query(sort: \Series.dateAdded, order: .reverse) private var allSeries: [Series]
    @Environment(SeriesManager.self) private var seriesManager

    private var premiumManager: PremiumManager { PremiumManager.shared }

    @State private var viewModel = MyLibraryViewModel()

    /// Show pending confirmation before removing (unfollowing).
    @State private var pendingRemoval: Series?

    /// Own nav stack — tapping a tile pushes into the same
    /// FollowedShowDetail the Timeline and My List tabs use.
    @State private var navigationPath = NavigationPath()

    @State private var viewMode: MyLibraryViewMode = .grid

    // Computed from @Query (auto-updates)
    private var syncedCount: Int { allSeries.filter { $0.isSynced }.count }

    /// Premium → only synced shows (removing one drops it out of the
    /// grid, since sync IS the premium feature). Free → every followed
    /// show — just a plain list of what's tracked on this device.
    private var gridShows: [Series] {
        effectivePremium ? allSeries.filter { $0.isSynced } : allSeries
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                // Status card + edit affordance — Premium only. Free
                // doesn't see any of the iCloud framing, just their shows.
                if effectivePremium {
                    MyLibraryStatusCard(
                        isPremium: true,
                        syncedCount: syncedCount
                    )
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 16)
                }

                // Section header
                MyLibrarySectionHeader(isEditMode: viewModel.isEditMode)
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 12)

                // Show grid or list
                Group {
                    if viewMode == .grid {
                        MyLibraryShowGrid(
                            shows: gridShows,
                            isPremium: effectivePremium,
                            isEditMode: viewModel.isEditMode,
                            onRemove: { series in
                                pendingRemoval = series
                            },
                            onSelect: { series in
                                navigationPath.append(series)
                            }
                        )
                    } else {
                        MyLibraryShowList(
                            shows: gridShows,
                            isPremium: effectivePremium,
                            isEditMode: viewModel.isEditMode,
                            onRemove: { series in
                                pendingRemoval = series
                            },
                            onSelect: { series in
                                navigationPath.append(series)
                            }
                        )
                    }
                }
                .padding(.horizontal, C2BLayout.horizontalPadding)
                .padding(.bottom, 24)
                // Anchored to the grid holding the X buttons, not the
                // ScrollView — iOS 26 places the bubble against the frame
                // of whatever the dialog is attached to.
                .confirmationDialog(
                    "Remove Show?",
                    isPresented: Binding(
                        get: { pendingRemoval != nil },
                        set: { if !$0 { pendingRemoval = nil } }
                    ),
                    titleVisibility: .visible,
                    presenting: pendingRemoval
                ) { series in
                    Button("Remove from Follow List", role: .destructive) {
                        removeAndUnfollow(series)
                    }
                    Button("Cancel", role: .cancel) { pendingRemoval = nil }
                } message: { series in
                    Text("\(series.name) will be removed from your follow list on every device.")
                }

                // Footer text
                footerText
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 100)
            }
        }
        .background(Color.c2bBackground)
        .gesture(
            // Long press to enter edit mode — both tiers. Removing a show
            // is local device management, not an iCloud feature.
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !viewModel.isEditMode {
                        viewModel.toggleEditMode()
                    }
                }
        )
        .onAppear {
            viewModel.configure(premiumManager: premiumManager)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(for: Series.self) { series in
            FollowedShowDetail(
                series: series,
                initialSeason: series.firstUnwatchedSeason?.seasonNumber,
                onDismiss: { navigationPath.removeLast() },
                onUnfollow: {
                    let id = series.id
                    Task { try? await seriesManager.unfollowAwaitingCloud(id: id) }
                }
            )
        }
        }
    }

    /// Deletes the show's iCloud backup (if any) and unfollows it.
    private func removeAndUnfollow(_ series: Series) {
        let id = series.id
        pendingRemoval = nil
        viewModel.exitEditMode()
        Task {
            // Waits for iCloud to confirm, and tombstones the id so restore
            // can't hand the show back if the delete fails.
            try? await seriesManager.unfollowAwaitingCloud(id: id)
        }
    }

    // MARK: - Effective Premium (respects debug toggle)

    private var effectivePremium: Bool {
        return premiumManager.isPremium
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("MY LIBRARY")
                .font(.custom(.oswald.bold, size: 27))
                .foregroundColor(.white)
                .tracking(1.2)

            Spacer()

            // Done button (edit mode) or the grid/list toggle
            if viewModel.isEditMode {
                Button(action: { viewModel.exitEditMode() }) {
                    Text("DONE")
                        .font(.custom(.oswald.bold, size: 14))
                        .foregroundColor(.c2bTeal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.c2bTeal.opacity(0.15))
                        .cornerRadius(8)
                }
            } else {
                MyLibraryViewModeToggle(mode: $viewMode)
            }
        }
        .padding(.horizontal, C2BLayout.horizontalPadding)
    }

    // MARK: - Footer

    private var footerText: some View {
        Text(effectivePremium ? premiumFooter : freeFooter)
            .font(.custom(.jetbrains.regular, size: 10.5))
            .foregroundColor(.white.opacity(0.35))
            .multilineTextAlignment(.center)
            .tracking(0.3)
    }

    private var premiumFooter: String {
        "This list shows what's backed up to iCloud. Removing a show deletes its backup on every device and removes it from your follow list."
    }

    private var freeFooter: String {
        "Every show you're currently tracking, in one place. Upgrade to Premium to back this up to iCloud and edit it from here."
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()
        Text("Preview requires app context")
            .foregroundColor(.white.opacity(0.5))
    }
}
