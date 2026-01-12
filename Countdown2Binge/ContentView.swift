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
    @Query(sort: \FollowedShow.followedAt, order: .reverse)
    private var followedShows: [FollowedShow]

    var body: some View {
        NavigationStack {
            Group {
                if followedShows.isEmpty {
                    ContentUnavailableView(
                        "No Shows Yet",
                        systemImage: "tv",
                        description: Text("Follow shows to track when they're ready to binge.")
                    )
                } else {
                    List {
                        ForEach(followedShows) { show in
                            if let cached = show.cachedData {
                                HStack {
                                    Text(cached.name)
                                    Spacer()
                                    Text(cached.lifecycleState.rawValue)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Show #\(show.tmdbId)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Countdown2Binge")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
}
