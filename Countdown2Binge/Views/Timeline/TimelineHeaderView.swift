//
//  TimelineHeaderView.swift
//  Countdown2Binge
//

import SwiftUI
import UIKit

/// Header for the Timeline screen showing last updated timestamp
struct TimelineHeaderView: View {
    let lastUpdated: Date?

    // Responsive sizing for smaller screens
    private var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 380
    }

    // Colors
    private let lastUpdatedColor = Color(red: 0x55/255, green: 0x55/255, blue: 0x55/255)

    private var lastUpdatedText: String {
        guard let date = lastUpdated else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Last updated: \(formatter.string(from: date).lowercased())"
    }

    var body: some View {
        VStack(spacing: 4) {
            // Last updated text (hidden on small screens to save space)
            if !lastUpdatedText.isEmpty && !isSmallScreen {
                Text(lastUpdatedText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(lastUpdatedColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, isSmallScreen ? 12 : 16)
        .padding(.top, 8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            TimelineHeaderView(lastUpdated: Date())
            Spacer()
        }
    }
}
