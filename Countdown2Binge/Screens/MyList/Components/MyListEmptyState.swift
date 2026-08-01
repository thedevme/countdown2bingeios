//
//  MyListEmptyState.swift
//  Countdown2Binge
//
//  Empty state view for My List tabs.
//

import SwiftUI

struct MyListEmptyState: View {
    let tab: MyListTab

    private var icon: String {
        switch tab {
        case .active: return "play.rectangle.on.rectangle"
        case .ended: return "tv"
        case .archived: return "archivebox"
        }
    }

    private var title: String {
        switch tab {
        case .active: return String(localized: "mylist_empty_active_title")
        case .ended: return String(localized: "mylist_empty_ended_title")
        case .archived: return String(localized: "mylist_empty_archived_title")
        }
    }

    private var subtitle: String {
        switch tab {
        case .active: return String(localized: "mylist_empty_active_sub")
        case .ended: return String(localized: "mylist_empty_ended_sub")
        case .archived: return String(localized: "mylist_empty_archived_sub")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.c2bMuted)

            Text(title)
                .font(.custom(.oswald.regular, size: 18))
                .foregroundColor(.c2bDim)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.c2bMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                .foregroundColor(.white.opacity(0.12))
        )
        .padding(.horizontal, 20)
    }
}
