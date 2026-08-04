//
//  DetailSynopsisSection.swift
//  Countdown2Binge
//
//  Overview/synopsis section with expandable "More" button.
//

import SwiftUI

struct DetailSynopsisSection: View {
    let overview: String?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let overview = overview, !overview.isEmpty {
                Text(overview)
                    .font(.system(size: 13.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .lineLimit(isExpanded ? nil : 3)

                if overview.count > 150 {
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Text(isExpanded ? String(localized: "button_show_less") : String(localized: "button_more"))
                            .font(.custom(.jetbrains.bold, size: 10))
                            .foregroundColor(.c2bTeal)
                            .tracking(0.8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DetailSynopsisSection(
        overview: "Twenty years after modern civilization has been destroyed, Joel, a hardened survivor, is hired to smuggle Ellie, a 14-year-old girl, out of an oppressive quarantine zone. What starts as a small job soon becomes a brutal, heartbreaking journey, as they both must traverse the U.S. and depend on each other for survival."
    )
    .padding()
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
