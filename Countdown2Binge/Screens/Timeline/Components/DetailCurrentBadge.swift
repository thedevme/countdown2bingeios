//
//  DetailCurrentBadge.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailCurrentBadge: View {
    var body: some View {
        Text("detail_current")
            .font(.custom(.jetbrains.bold, size: 8))
            .foregroundColor(.c2bTealBright)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.c2bTeal.opacity(0.12))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.c2bTealLine, lineWidth: 1)
            )
    }
}
