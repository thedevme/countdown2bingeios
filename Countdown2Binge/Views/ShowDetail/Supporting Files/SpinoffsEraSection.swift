//
//  SpinoffsEraSection.swift
//  Countdown2Binge
//
//  Entry point for the new, era-grouped Spin-offs card (design ref:
//  "claude design/project/Spin-offs Wide Row.html", V3). Backed by
//  FranchiseCatalog.swift (BundledFranchiseProvider) — a second, currently
//  separate engine from FranchiseService/Franchises.json already live on
//  this screen. This view is not wired into FollowedShowDetail yet.
//
//  Also hosts the small pieces shared by the full (premium) and locked
//  (free) states below: the order toggle, the "chd" header, and the
//  era-group header row.
//

import SwiftUI
import UIKit

// MARK: - Entry Point

struct SpinoffsEraSection: View {
    let franchiseGroup: FranchiseGroup?
    let showTitle: String
    let isPremium: Bool
    let posterURLs: [MediaKey: URL]
    let onEntryTap: (FranchiseEntry) -> Void
    let onUnlockTap: () -> Void

    var body: some View {
        // Franchise data is checked first: a show with nothing to sequence has
        // nothing to gate either, so free and premium users see the same
        // empty state. The premium check only matters once there's real
        // content behind it.
        if let franchiseGroup {
            if isPremium {
                SpinoffsEraCard(
                    franchiseGroup: franchiseGroup,
                    posterURLs: posterURLs,
                    onEntryTap: onEntryTap
                )
            } else {
                SpinoffsEraLockedCard(
                    franchiseGroup: franchiseGroup,
                    posterURLs: posterURLs,
                    onUnlockTap: onUnlockTap
                )
            }
        } else {
            SpinoffsEmptyState(showTitle: showTitle)
        }
    }
}

// MARK: - Display Order

/// The release-vs-story toggle. Both are real, already-decoded data:
/// `.recommended` is `FranchiseCatalogBuilder`'s own bucket+year sort, baked
/// into `FranchiseGroup.sections` already; `.release` re-ranks every entry
/// across all sections by year alone, ignoring bucket — entries keep their
/// era grouping for display, only the number shown changes (and can jump
/// between groups in this mode, exactly as the design doc's own note says).
enum FranchiseDisplayOrder: String, CaseIterable, Identifiable, Hashable {
    case recommended
    case release

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recommended: return String(localized: "franchise_order_recommended")
        case .release: return String(localized: "franchise_order_release")
        }
    }

    var explanation: String {
        switch self {
        case .recommended: return String(localized: "franchise_order_recommended_desc")
        case .release: return String(localized: "franchise_order_release_desc")
        }
    }
}

// Ordering/numbering logic lives in FranchiseSpinoffOrdering.swift — the
// pure, directly-testable function both cards use. (Previously duplicated
// here as `franchiseReleaseRanks`, which computed correct ranks but was
// never actually applied to row layout — see FranchiseSpinoffOrdering.swift
// for the fix and why it's a separate file.)

// MARK: - Header ("chd")

struct SpinoffsEraHeader: View {
    let label: String
    /// nil omits the badge entirely — used for states with nothing to gate.
    let badgeText: String?
    let count: Int

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Text(label.uppercased())
                .font(.custom(.jetbrains.bold, size: 8))
                .tracking(1.4)
                .foregroundColor(.c2bMuted)

            if let badgeText {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 8))
                    Text(badgeText.uppercased())
                }
                .font(.custom(.jetbrains.bold, size: 7.5))
                .tracking(1.2)
                .foregroundColor(.c2bTealBright)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                StrokedText(
                    "\(count)",
                    fontName: CustomFont.oswaldBold.rawValue,
                    fontSize: 32,
                    strokeColor: UIColor(Color.c2bTeal.opacity(0.55)),
                    strokeWidth: 1.6
                )
                .frame(width: 40, height: 26)

                Text(String(localized: "franchise_spinoffs_count \(count)"))
                    .font(.custom(.jetbrains.bold, size: 7.5))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bMuted)
            }
        }
        .padding(.horizontal, 15)
        .padding(.top, 14)
        .padding(.bottom, 11)
    }
}

// MARK: - Order Toggle

struct SpinoffsOrderToggle: View {
    @Binding var order: FranchiseDisplayOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                ForEach(FranchiseDisplayOrder.allCases) { option in
                    Button {
                        order = option
                    } label: {
                        Text(option.label.uppercased())
                            .font(.custom(.jetbrains.bold, size: 8))
                            .tracking(0.8)
                            .foregroundColor(order == option ? .c2bTealBright : .c2bMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(order == option ? Color.c2bTeal.opacity(0.16) : Color.clear)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )

            Text(order.explanation)
                .font(.system(size: 10.5))
                .foregroundColor(.c2bMuted)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 13)
    }
}

// MARK: - Era Group Header

struct SpinoffsEraGroupHeader: View {
    let title: String
    let entryCount: Int
    /// 1-based position of this era among the sections actually shown.
    let index: Int
    /// Greyed treatment for an era that's sealed in the locked state.
    var isSealed: Bool = false

    private var entryCountText: String {
        entryCount == 1
            ? String(localized: "franchise_entry_singular")
            : String(localized: "franchise_entries_count \(entryCount)")
    }

    var body: some View {
        HStack(spacing: 10) {
            StrokedText(
                String(format: "%02d", index),
                fontName: CustomFont.oswaldBold.rawValue,
                fontSize: 44,
                strokeColor: UIColor(isSealed ? Color.white.opacity(0.22) : Color.c2bTeal.opacity(0.55)),
                strokeWidth: 1.6
            )
            .frame(width: 50, height: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.custom(.oswald.bold, size: 15))
                    .tracking(0.8)
                    .foregroundColor(isSealed ? .c2bMuted : .c2bText)
                    .lineLimit(1)

                Text(entryCountText.uppercased())
                    .font(.custom(.jetbrains.bold, size: 7.5))
                    .tracking(1.2)
                    .foregroundColor(.c2bMuted)
            }

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
        .padding(.vertical, 9)
    }
}

// MARK: - Empty State

/// Shown when this specific show isn't part of any known franchise — the
/// "STANDALONE SERIES" card. Shown to everyone regardless of premium status:
/// there's nothing to gate here. Relocated from the now-removed
/// ShowDetailSpinoffsSection.swift (old franchise engine) — unchanged.
struct SpinoffsEmptyState: View {
    let showTitle: String

    var body: some View {
        VStack(spacing: 16) {
            // Eyebrow + count header — a standalone show is a "universe" of
            // exactly one entry: itself.
            HStack {
                Text("label_universe")
                    .font(.custom(.jetbrains.bold, size: 10))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bMuted)

                Spacer()

                Text("1")
                    .font(.custom(.oswald.bold, size: 22))
                    .foregroundColor(.c2bDim)
            }

            Image(systemName: "calendar")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.c2bMuted)
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(spacing: 6) {
                Text("empty_no_spinoffs")
                    .font(.custom(.oswald.bold, size: 17))
                    .foregroundColor(.c2bDim)
                    .tracking(0.34)  // 0.02em = 17 * 0.02 = 0.34
                    .textCase(.uppercase)

                Text(String(localized: "empty_no_spinoffs_message \(showTitle)"))
                    .font(.system(size: 12))
                    .foregroundColor(.c2bMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)  // 12 * 1.5 = 18, lineSpacing = 18 - 12 = 6
            }

            Text("label_nothing_to_sequence")
                .font(.custom(.jetbrains.bold, size: 10))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
