//
//  SpinoffsEraCard.swift
//  Countdown2Binge
//
//  Full/premium state of the Spin-offs card. Era headers and section
//  grouping stay fixed (story order) in BOTH toggle states, matching the
//  design ref ("Spin-offs Wide Row.html", V3) — only the order of entries
//  *within* each era section, and the number shown on each, changes with
//  the toggle. That's also why the RELEASE note warns numbers "jump between
//  groups": the parent can release-rank ahead of its own prequels while
//  still displaying under the "Before" era header.
//  Ordering/numbering logic lives in FranchiseSpinoffOrdering.swift, not here.
//

import SwiftUI

struct SpinoffsEraCard: View {
    let franchiseGroup: FranchiseGroup
    let posterURLs: [MediaKey: URL]
    let onEntryTap: (FranchiseEntry) -> Void

    @State private var order: FranchiseDisplayOrder = .recommended

    var body: some View {
        VStack(spacing: 0) {
            SpinoffsEraHeader(
                label: String(localized: "label_universe"),
                badgeText: String(localized: "badge_premium"),
                count: franchiseGroup.totalEntryCount
            )

            SpinoffsOrderToggle(order: $order)

            groupedList
                .padding(.horizontal, 15)
                .padding(.bottom, 6)

            if order == .release {
                Text(String(localized: "franchise_order_release_note"))
                    .font(.system(size: 10.5))
                    .foregroundColor(.c2bAmber)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 15)
            } else {
                Color.clear.frame(height: 6)
            }
        }
        .background(Color.c2bCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Era-grouped list (headers always shown; entry order within each
    // section, and the number on each entry, follow the toggle)

    private var groupedList: some View {
        let ordered = FranchiseSpinoffOrdering.orderedEntries(for: franchiseGroup, order: order)
        let numberByKey = Dictionary(uniqueKeysWithValues: ordered.map { ($0.entry.id, $0.displayNumber) })

        return VStack(spacing: 0) {
            ForEach(Array(franchiseGroup.sections.enumerated()), id: \.element.bucket) { index, section in
                if franchiseGroup.showsSectionHeaders {
                    SpinoffsEraGroupHeader(
                        title: section.title,
                        entryCount: section.entries.count,
                        index: index + 1
                    )
                }

                // RECOMMENDED keeps the section's own (story) order. RELEASE
                // re-sorts just the entries within this section by their
                // release-order number — the section itself stays put, which
                // is exactly why numbers can "jump" between sections.
                let sectionEntries = order == .release
                    ? section.entries.sorted { (numberByKey[$0.id] ?? 0) < (numberByKey[$1.id] ?? 0) }
                    : section.entries

                ForEach(sectionEntries) { entry in
                    SpinoffsEraEntryRow(
                        entry: entry,
                        displayNumber: numberByKey[entry.id] ?? 1,
                        posterURL: posterURLs[entry.id],
                        onTap: { onEntryTap(entry) }
                    )
                    .padding(.bottom, 9)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        SpinoffsEraCard(
            franchiseGroup: FranchiseGroup(
                franchiseName: "Forward Hold Universe",
                sections: [
                    FranchiseSection(bucket: .before, title: "Before the War", entries: [
                        FranchiseEntry(id: MediaKey(tmdbId: 2, mediaType: .tv), tmdbId: 2, mediaType: .tv,
                                       title: "Forward Hold: Muster", years: "2019", displayNumber: 1,
                                       relationLabel: "Prequel", statusLabel: nil,
                                       note: "How the multinational unit was assembled, one recruit at a time.",
                                       isCurrentShow: false, isMainSeries: false)
                    ]),
                    FranchiseSection(bucket: .main, title: "The Main Series", entries: [
                        FranchiseEntry(id: MediaKey(tmdbId: 1, mediaType: .tv), tmdbId: 1, mediaType: .tv,
                                       title: "Forward Hold", years: "2021", displayNumber: 2,
                                       relationLabel: "Main Series", statusLabel: nil, note: nil,
                                       isCurrentShow: true, isMainSeries: true)
                    ]),
                    FranchiseSection(bucket: .after, title: "After the War", entries: [
                        FranchiseEntry(id: MediaKey(tmdbId: 3, mediaType: .tv), tmdbId: 3, mediaType: .tv,
                                       title: "Kestrel", years: "2025", displayNumber: 3,
                                       relationLabel: "Spin-off", statusLabel: "Announced",
                                       note: "Forward Hold's sharpest operator gets her own command, and a mission nobody signed off on.",
                                       isCurrentShow: false, isMainSeries: false)
                    ])
                ],
                showsSectionHeaders: true,
                totalEntryCount: 3
            ),
            posterURLs: [:],
            onEntryTap: { _ in }
        )
        .padding(16)
    }
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
