//
//  SpinoffsEraLockedCard.swift
//  Countdown2Binge
//
//  Free-user state of the era-grouped Spin-offs card: only the era the
//  current show sits in is readable (and only the current show within it —
//  siblings in that same era seal too); every other era is fully sealed.
//  The order toggle still works, same as the full state.
//

import SwiftUI

struct SpinoffsEraLockedCard: View {
    let franchiseGroup: FranchiseGroup
    let posterURLs: [MediaKey: URL]
    let onUnlockTap: () -> Void

    @State private var order: FranchiseDisplayOrder = .recommended

    // Locked state keeps its era-sealed layout regardless of order — only
    // the current show is ever really visible here, one era at a time, so a
    // fully flat global RELEASE re-sort (which can interleave sealed eras)
    // doesn't apply the way it does in the full card. The order toggle still
    // changes the NUMBER shown for the one visible entry, computed the same
    // way SpinoffsEraCard does — no separate, possibly-drifting logic here.
    private func displayNumber(for entry: FranchiseEntry) -> Int {
        FranchiseSpinoffOrdering.orderedEntries(for: franchiseGroup, order: order)
            .first { $0.entry.id == entry.id }?.displayNumber ?? 1
    }

    /// The bucket containing the show being viewed — the only one that opens.
    private var openBucket: FranchiseBucket? {
        franchiseGroup.sections.first { $0.entries.contains { $0.isCurrentShow } }?.bucket
    }

    /// Everything but the show being viewed.
    private var totalHidden: Int {
        max(0, franchiseGroup.totalEntryCount - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            SpinoffsEraHeader(
                label: String(localized: "label_universe"),
                badgeText: String(localized: "franchise_badge_premium_only"),
                count: franchiseGroup.totalEntryCount
            )

            SpinoffsOrderToggle(order: $order)

            VStack(spacing: 0) {
                ForEach(Array(franchiseGroup.sections.enumerated()), id: \.element.bucket) { index, section in
                    let isOpen = section.bucket == openBucket

                    if franchiseGroup.showsSectionHeaders {
                        SpinoffsEraGroupHeader(
                            title: section.title,
                            entryCount: section.entries.count,
                            index: index + 1,
                            isSealed: !isOpen
                        )
                    }

                    if isOpen {
                        // Within the open era, only the current show itself
                        // renders — any sibling entries in that same era seal too.
                        let shown = section.entries.filter(\.isCurrentShow)
                        let sealedInEra = section.entries.count - shown.count

                        ForEach(shown) { entry in
                            SpinoffsEraEntryRow(
                                entry: entry,
                                displayNumber: displayNumber(for: entry),
                                posterURL: posterURLs[entry.id],
                                onTap: {}
                            )
                            .padding(.bottom, 9)
                        }

                        if sealedInEra > 0 {
                            SpinoffsEraSealedRow(hiddenCount: sealedInEra)
                                .padding(.bottom, 9)
                        }
                    } else {
                        SpinoffsEraSealedRow(hiddenCount: section.entries.count)
                            .padding(.bottom, 9)
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 6)

            if order == .release {
                Text(String(localized: "franchise_order_release_note"))
                    .font(.system(size: 10.5))
                    .foregroundColor(.c2bAmber)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 13)
            }

            SpinoffsEraUnlockBar(hiddenCount: totalHidden, onTap: onUnlockTap)
        }
        .background(Color.c2bCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ScrollView {
        SpinoffsEraLockedCard(
            franchiseGroup: FranchiseGroup(
                franchiseName: "Forward Hold Universe",
                sections: [
                    FranchiseSection(bucket: .before, title: "Before the War", entries: [
                        FranchiseEntry(id: MediaKey(tmdbId: 2, mediaType: .tv), tmdbId: 2, mediaType: .tv,
                                       title: "Forward Hold: Muster", years: "2019", displayNumber: 1,
                                       relationLabel: "Prequel", statusLabel: nil, note: nil,
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
                                       relationLabel: "Spin-off", statusLabel: "Announced", note: nil,
                                       isCurrentShow: false, isMainSeries: false),
                        FranchiseEntry(id: MediaKey(tmdbId: 4, mediaType: .tv), tmdbId: 4, mediaType: .tv,
                                       title: "The Outpost", years: "2026", displayNumber: 4,
                                       relationLabel: "Spin-off", statusLabel: nil, note: nil,
                                       isCurrentShow: false, isMainSeries: false)
                    ])
                ],
                showsSectionHeaders: true,
                totalEntryCount: 4
            ),
            posterURLs: [:],
            onUnlockTap: {}
        )
        .padding(16)
    }
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
