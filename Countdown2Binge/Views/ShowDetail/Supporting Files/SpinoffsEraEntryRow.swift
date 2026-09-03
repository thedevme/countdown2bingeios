//
//  SpinoffsEraEntryRow.swift
//  Countdown2Binge
//
//  One entry ("unit") in the era-grouped Spin-offs card: backdrop art with
//  an ordinal + title/tag overlay, and a description line below. Shared by
//  the full and locked states in SpinoffsEraCard / SpinoffsEraLockedCard.
//

import SwiftUI

struct SpinoffsEraEntryRow: View {
    let entry: FranchiseEntry
    /// Recommended-order number by default, but the caller may pass the
    /// release-order rank instead when that toggle is active.
    let displayNumber: Int
    let posterURL: URL?
    let onTap: () -> Void

    private var tagText: String {
        var parts = [entry.relationLabel]
        if entry.isCurrentShow {
            parts.append(String(localized: "franchise_you_are_here"))
        } else if let statusLabel = entry.statusLabel {
            parts.append(statusLabel)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                artHeader

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundColor(.c2bDim)
                        .lineSpacing(4.5)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.top, 9)
                        .padding(.bottom, 10)
                }
            }
            .background(entry.isCurrentShow ? Color.c2bTeal.opacity(0.08) : Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(entry.isCurrentShow ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Movie entries have no follow path today (TMDB TV-only lookups) —
        // same reasoning as the follow button gating elsewhere in this feature.
        .disabled(!entry.isFollowable)
        .opacity(entry.isFollowable ? 1 : 0.6)
    }

    private var artHeader: some View {
        ZStack(alignment: .leading) {
            BackdropView(url: posterURL, height: 72)
                .brightness(-0.3)
                .saturation(0.9)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.92),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.24)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(alignment: .center, spacing: 9) {
                Text("\(displayNumber)")
                    .font(.custom(.oswald.bold, size: 18))
                    .foregroundColor(.c2bTealBright)
                    .frame(width: 22, alignment: .center)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title.uppercased())
                        .font(.custom(.oswald.bold, size: 16.5))
                        .foregroundColor(entry.isCurrentShow ? .c2bTealBright : .c2bText)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(tagText.uppercased())
                        .font(.custom(.jetbrains.bold, size: 7.5))
                        .tracking(1.2)
                        .foregroundColor(entry.isCurrentShow ? .c2bTeal : .c2bDim)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Sealed placeholder (locked state)

struct SpinoffsEraSealedRow: View {
    let hiddenCount: Int

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(.c2bMuted)

            Text((hiddenCount == 1 ? String(localized: "franchise_entry_singular") : String(localized: "franchise_entries_count \(hiddenCount)")).uppercased()
                 + " · " + String(localized: "franchise_hidden_count \(hiddenCount)").uppercased())
                .font(.custom(.jetbrains.bold, size: 8))
                .tracking(1.2)
                .foregroundColor(.c2bMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundColor(Color.white.opacity(0.17))
        )
    }
}

// MARK: - Unlock bar (locked state footer)

struct SpinoffsEraUnlockBar: View {
    let hiddenCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.13), lineWidth: 1)
                        )
                        .frame(width: 26, height: 26)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.c2bDim)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(localized: "franchise_unlock_bar_title \(hiddenCount)"))
                        .font(.custom(.oswald.medium, size: 12.5))
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(String(localized: "franchise_unlock_bar_subtitle"))
                        .font(.system(size: 10.5))
                        .foregroundColor(.c2bMuted)
                }

                Spacer(minLength: 0)

                Text(String(localized: "franchise_unlock").uppercased())
                    .font(.custom(.jetbrains.bold, size: 7.5))
                    .tracking(1.4)
                    .foregroundColor(.c2bTealBright)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.02))
        }
        .buttonStyle(.plain)
    }
}
