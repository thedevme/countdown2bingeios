//
//  WatchOrderRow.swift
//  Countdown2Binge
//
//  One row in the Watch Order sheet — position number, poster, title +
//  time-left (own lines, not run together), up/down buttons. Design ref:
//  "My List Cards.html" — `.ro`.
//

import SwiftUI
import UIKit

struct WatchOrderRow: View {
    let position: Int
    let posterURL: URL?
    let title: String
    /// Whole-show remaining watch time, already formatted as "Xh:XXm:XXs".
    let timeLeftText: String
    let tone: Color
    let isFirst: Bool
    let isLast: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            StrokedText(
                "\(position)",
                fontName: CustomFont.oswaldBold.rawValue,
                fontSize: 17,
                strokeColor: UIColor(tone),
                strokeWidth: 1.2
            )
            .frame(width: 20, height: 20)

            // Explicit width AND height — width-only lets `.aspectRatio(.fit)`
            // resolve against this HStack's shorter proposed height instead
            // of the width given, squashing it into a slim rectangle.
            PosterView(url: posterURL, width: 38, height: 57, cornerRadius: 6)
                .brightness(-0.15)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom(.oswald.medium, size: 14))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Own line, per design — never run together with the title.
                Text("\(timeLeftText) LEFT")
                    .font(.custom(.jetbrains.regular, size: 7.5))
                    .tracking(1)
                    .foregroundColor(.c2bMuted)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                moveButton(systemName: "chevron.up", disabled: isFirst, action: onMoveUp)
                moveButton(systemName: "chevron.down", disabled: isLast, action: onMoveDown)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func moveButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(disabled ? .white.opacity(0.28) : .white.opacity(0.8))
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

#Preview {
    VStack(spacing: 8) {
        WatchOrderRow(
            position: 1, posterURL: nil, title: "Redwood Falls",
            timeLeftText: "5h:12m:00s", tone: .c2bTealBright,
            isFirst: true, isLast: false, onMoveUp: {}, onMoveDown: {}
        )
        WatchOrderRow(
            position: 2, posterURL: nil, title: "Forward Hold",
            timeLeftText: "6h:14m:56s", tone: .c2bTealBright,
            isFirst: false, isLast: false, onMoveUp: {}, onMoveDown: {}
        )
        WatchOrderRow(
            position: 3, posterURL: nil, title: "Iron Veil",
            timeLeftText: "101h:06m:54s", tone: .c2bTealBright,
            isFirst: false, isLast: true, onMoveUp: {}, onMoveDown: {}
        )
    }
    .padding(20)
    .background(Color.c2bBackground)
}
