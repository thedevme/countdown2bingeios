//
//  ContentView.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 1/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TimelineView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
}
