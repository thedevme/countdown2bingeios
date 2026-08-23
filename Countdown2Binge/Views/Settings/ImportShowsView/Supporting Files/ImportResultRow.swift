//
//  ImportResultRow.swift
//  Countdown2Binge
//
//  Molecule — one title's progress through the import. Each row settles on its
//  own the moment its own fetch lands, so the list fills in out of order.
//  Ported from c2b-import.jsx's "Ready to add" rows.
//

import SwiftUI

/// Where a single pasted title has got to. Rows move from `.waiting` through
/// `.searching` to a settled state, independently of every other row.
enum ImportItemState: Equatable {
    case waiting
    case searching
    case added(posterURL: URL?, matchedTitle: String, network: String)
    case alreadyFollowing(matchedTitle: String)
    case notFound
    case failed
}

struct ImportResultRow: View {
    /// What the user typed, cleaned.
    let title: String
    let state: ImportItemState

    var body: some View {
        HStack(spacing: 11) {
            artwork

            VStack(alignment: .leading, spacing: 5) {
                Text(displayTitle)
                    .font(.custom(.oswald.bold, size: 15))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)

                Text(statusLine)
                    .font(.custom(.jetbrains.regular, size: 7.5))
                    .tracking(0.75)
                    .textCase(.uppercase)
                    .foregroundColor(statusColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailingGlyph
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(borderColor, style: StrokeStyle(lineWidth: 1, dash: isSettledMiss ? [3, 3] : []))
        )
        .animation(.easeOut(duration: 0.22), value: state)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var artwork: some View {
        switch state {
        case .added(let url, _, _):
            PosterView(url: url, width: 30, cornerRadius: 5)
                .frame(width: 30, height: 45)
        default:
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.05))
                .frame(width: 30, height: 45)
        }
    }

    @ViewBuilder
    private var trailingGlyph: some View {
        switch state {
        case .waiting, .searching:
            ProgressView()
                .controlSize(.small)
                .tint(.c2bTeal)
        case .added, .alreadyFollowing:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.c2bTealBright)
        case .notFound, .failed:
            Image(systemName: "questionmark")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.c2bMuted)
        }
    }

    // MARK: - Copy

    /// Once matched, show TMDB's title — it's what actually got followed, and
    /// seeing it confirms the right show was picked.
    private var displayTitle: String {
        switch state {
        case .added(_, let matched, _), .alreadyFollowing(let matched): return matched
        default: return title
        }
    }

    private var statusLine: String {
        switch state {
        case .waiting:                  return String(localized: "import_state_waiting")
        case .searching:                return String(localized: "import_state_searching")
        case .added(_, _, let network): return network.isEmpty
                                            ? String(localized: "import_state_added")
                                            : network
        case .alreadyFollowing:         return String(localized: "import_state_already")
        case .notFound:                 return String(localized: "import_state_not_found")
        case .failed:                   return String(localized: "import_state_failed")
        }
    }

    private var statusColor: Color {
        switch state {
        case .added, .alreadyFollowing: return .c2bMuted
        case .notFound, .failed:        return .c2bDim
        default:                        return .c2bMuted
        }
    }

    private var isSettledMiss: Bool {
        state == .notFound || state == .failed
    }

    private var background: Color {
        switch state {
        case .added, .alreadyFollowing: return Color.c2bTeal.opacity(0.06)
        default:                        return Color.white.opacity(0.03)
        }
    }

    private var borderColor: Color {
        switch state {
        case .added, .alreadyFollowing: return .c2bTealLine
        default:                        return Color.white.opacity(0.14)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ImportResultRow(title: "Echo 7", state: .waiting)
        ImportResultRow(title: "Forward Hold", state: .searching)
        ImportResultRow(title: "Iron Veil", state: .added(posterURL: nil, matchedTitle: "Iron Veil", network: "STARZ"))
        ImportResultRow(title: "North Watch", state: .alreadyFollowing(matchedTitle: "North Watch"))
        ImportResultRow(title: "Blakwater Piont", state: .notFound)
        ImportResultRow(title: "Vice Coast", state: .failed)
    }
    .padding()
    .background(Color.c2bBackground)
}
