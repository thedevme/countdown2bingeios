//
//  ContentView.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 1/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .timeline
    #if DEBUG
    @State private var showDemoIndicator = false
    #endif

    enum Tab: Hashable {
        case timeline
        case planner
        case bingeReady
        case settings
        case search
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Timeline Tab
                SwiftUI.Tab("Timeline", systemImage: "calendar.day.timeline.left", value: Tab.timeline) {
                    TimelineView()
                }

                // Planner Tab
                SwiftUI.Tab("Planner", systemImage: "list.bullet.clipboard", value: Tab.planner) {
                    PlannerView()
                }

                // Binge Ready Tab
                SwiftUI.Tab("Binge Ready", systemImage: "calendar", value: Tab.bingeReady) {
                    BingeReadyTab(modelContext: modelContext)
                }

                // Settings Tab
                SwiftUI.Tab("Settings", systemImage: "gearshape", value: Tab.settings) {
                    SettingsView()
                }

                // Search Tab (accessory role - appears as icon in tab bar)
                SwiftUI.Tab(value: Tab.search, role: .search) {
                    SearchTab(modelContext: modelContext)
                }
            }
            .tint(.white)
            .onAppear {
                configureTabBarAppearance()
            }

            #if DEBUG
            // Demo mode indicator (only in debug builds)
            if showDemoIndicator {
                DemoModeIndicator()
            }
            #endif
        }
        #if DEBUG
        .onShake {
            DemoModeProvider.shared.toggle()
            showDemoIndicator = DemoModeProvider.shared.isEnabled

            // Hide indicator after delay if still in demo mode
            if showDemoIndicator {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showDemoIndicator = false
                }
            }
        }
        #endif
    }

    // MARK: - Tab Bar Appearance

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.06, alpha: 1.0)

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.4, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.4, alpha: 1.0)
        ]

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Tab Wrappers

/// Wrapper view that persists the BingeReadyViewModel
private struct BingeReadyTab: View {
    let modelContext: ModelContext
    @State private var viewModel: BingeReadyViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                BingeReadyView(viewModel: viewModel)
            } else {
                Color.black
                    .onAppear {
                        let repository = ShowRepository(modelContext: modelContext)
                        viewModel = BingeReadyViewModel(repository: repository)
                    }
            }
        }
    }
}

/// Wrapper view that persists the SearchViewModel
private struct SearchTab: View {
    let modelContext: ModelContext
    @State private var viewModel: SearchViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                SearchView(viewModel: viewModel)
            } else {
                Color.black
                    .onAppear {
                        let repository = ShowRepository(modelContext: modelContext)
                        let tmdbService = TMDBService()
                        let addShowUseCase = AddShowUseCase(tmdbService: tmdbService, repository: repository)
                        viewModel = SearchViewModel(
                            tmdbService: tmdbService,
                            addShowUseCase: addShowUseCase,
                            repository: repository
                        )
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
        .preferredColorScheme(.dark)
}
