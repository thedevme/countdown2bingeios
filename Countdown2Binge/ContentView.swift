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

    enum Tab: Hashable {
        case timeline
        case bingeReady
        case search
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Timeline Tab
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(Tab.timeline)

            // Binge Ready Tab
            BingeReadyTab(modelContext: modelContext)
                .tabItem {
                    Label("Binge Ready", systemImage: "checkmark.circle")
                }
                .tag(Tab.bingeReady)

            // Search Tab
            SearchTab(modelContext: modelContext)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(.white)
        .onAppear {
            configureTabBarAppearance()
        }
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
