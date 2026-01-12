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
            BingeReadyView(viewModel: makeBingeReadyViewModel())
                .tabItem {
                    Label("Binge Ready", systemImage: "checkmark.circle")
                }
                .tag(Tab.bingeReady)

            // Search Tab
            SearchView(viewModel: makeSearchViewModel())
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)
        }
        .tint(.white)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    // MARK: - ViewModel Factories

    private func makeBingeReadyViewModel() -> BingeReadyViewModel {
        let repository = ShowRepository(modelContext: modelContext)
        return BingeReadyViewModel(repository: repository)
    }

    private func makeSearchViewModel() -> SearchViewModel {
        let repository = ShowRepository(modelContext: modelContext)
        let tmdbService = TMDBService()
        let addShowUseCase = AddShowUseCase(tmdbService: tmdbService, repository: repository)
        return SearchViewModel(
            tmdbService: tmdbService,
            addShowUseCase: addShowUseCase,
            repository: repository
        )
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

#Preview {
    ContentView()
        .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
        .preferredColorScheme(.dark)
}
