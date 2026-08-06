//
//  CloudSyncSectionHeader.swift
//  Countdown2Binge
//
//  Section header for CloudSync grid showing state labels.
//

import SwiftUI

struct CloudSyncSectionHeader: View {
    let isEditMode: Bool
    let isPremium: Bool

    private var rightText: String {
        if !isPremium {
            return "LOCKED"
        }
        return isEditMode ? "TAP × TO REMOVE" : "HOLD TO EDIT"
    }

    var body: some View {
        HStack {
            Text("SHOWS SYNCED")
                .font(.custom(.jetbrains.bold, size: 9))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.8)

            Spacer()

            Text(rightText)
                .font(.custom(.jetbrains.regular, size: 9))
                .foregroundColor(.white.opacity(0.35))
                .tracking(0.8)
        }
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        VStack(spacing: 24) {
            CloudSyncSectionHeader(isEditMode: false, isPremium: true)
            CloudSyncSectionHeader(isEditMode: true, isPremium: true)
            CloudSyncSectionHeader(isEditMode: false, isPremium: false)
        }
        .padding()
    }
}
