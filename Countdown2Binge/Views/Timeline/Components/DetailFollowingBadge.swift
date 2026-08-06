//
//  DetailFollowingBadge.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailFollowingBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 12))
                .foregroundColor(.c2bTealBright)
            Text("button_following")
                .font(.custom(.jetbrains.bold, size: 9))
                .foregroundColor(.c2bTealBright)
                .textCase(.uppercase)
                .tracking(1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Color.c2bTeal.opacity(0.16))
        .cornerRadius(999)
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}
