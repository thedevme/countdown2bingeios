//
//  MyLibrarySectionHeader.swift
//  Countdown2Binge
//
//  A single centered hint line under the "MY LIBRARY" title — removing a
//  show is local device management, not an iCloud feature, so this reads
//  the same for both tiers. Swaps to the edit-mode hint once the grid is
//  jiggling.
//

import SwiftUI

struct MyLibrarySectionHeader: View {
    let isEditMode: Bool

    var body: some View {
        Text(isEditMode ? "TAP × TO REMOVE" : "LONG PRESS TO DELETE")
            .font(.custom(.jetbrains.medium, size: 10))
            .tracking(1.4)
            .foregroundColor(.white.opacity(0.35))
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    VStack(spacing: 24) {
        MyLibrarySectionHeader(isEditMode: false)
        MyLibrarySectionHeader(isEditMode: true)
    }
    .padding()
    .background(Color.c2bBackground)
}
