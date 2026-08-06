//
//  AddShowStatusCard.swift
//  Countdown2Binge
//
//  Status card showing the current lifecycle phase with description and stat.
//

import SwiftUI

struct AddShowStatusCard: View {
    let title: String
    let description: String
    let stat: String
    let statLabel: String
    let isDimmed: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Circle()
                .fill(isDimmed ? Color.white.opacity(0.06) : Color.c2bTeal.opacity(0.16))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(isDimmed ? Color.white.opacity(0.12) : Color.c2bTealLine, lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .fill(isDimmed ? Color.c2bMuted : Color.c2bTeal)
                        .frame(width: 12, height: 12)
                        .shadow(color: isDimmed ? .clear : Color.c2bTeal.opacity(0.5), radius: 8)
                )

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.custom(.oswald.bold, size: 22))
                    .foregroundColor(isDimmed ? .c2bDim : .white)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.c2bMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Stat
            VStack(spacing: 4) {
                Text(stat)
                    .font(.custom(.oswald.bold, size: stat.count <= 3 ? 32 : 22))
                    .foregroundColor(isDimmed ? .c2bMuted : .white)

                Text(statLabel.uppercased())
                    .font(.custom(.jetbrains.bold, size: 7))
                    .tracking(0.7)
                    .foregroundColor(.c2bDim)
            }
            .frame(minWidth: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            isDimmed
                ? AnyShapeStyle(Color.white.opacity(0.03))
                : AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.c2bTeal.opacity(0.12), Color.c2bTeal.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDimmed ? Color.white.opacity(0.08) : Color.c2bTealLine, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        AddShowStatusCard(
            title: "Anticipated",
            description: "No release date announced. We'll alert you the moment one drops.",
            stat: "TBD",
            statLabel: "No Date Yet",
            isDimmed: true
        )

        AddShowStatusCard(
            title: "Now Airing",
            description: "Episodes releasing weekly. We'll tell you the day the finale airs.",
            stat: "5",
            statLabel: "Days to Finale",
            isDimmed: false
        )
    }
    .padding(20)
    .background(Color.c2bBackground)
}
