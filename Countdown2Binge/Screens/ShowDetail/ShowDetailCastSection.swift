//
//  ShowDetailCastSection.swift
//  Countdown2Binge
//
//  Horizontal scrollable cast avatars section.
//

import SwiftUI

struct ShowDetailCastSection: View {
    let cast: [TMDBCastMember]

    private let avatarSize: CGFloat = 72

    var body: some View {
        if !cast.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                // Section header
                HStack {
                    Text("header_cast_crew")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .foregroundColor(.c2bMuted)
                        .tracking(1.4)

                    Spacer()

                    DirectionalIcon(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.c2bMuted)
                }

                // Horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(cast.prefix(10)) { member in
                            CastMemberCard(
                                member: member,
                                avatarSize: avatarSize
                            )
                        }
                    }
                }
                .padding(.horizontal, -22)
                .padding(.leading, 22)
            }
            .padding(.top, 22)
        }
    }
}

// MARK: - Cast Member Card
private struct CastMemberCard: View {
    let member: TMDBCastMember
    let avatarSize: CGFloat

    private var profileURL: URL? {
        guard let path = member.profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    private var initials: String {
        let parts = member.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(member.name.prefix(2))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            if let url = profileURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: avatarSize, height: avatarSize)
                            .clipShape(Circle())
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }

            // Name
            Text(member.name)
                .font(.custom(.jetbrains.bold, size: 9))
                .foregroundColor(.c2bText)
                .lineLimit(1)

            // Character
            if let character = member.character, !character.isEmpty {
                Text(character)
                    .font(.custom(.jetbrains.regular, size: 8))
                    .foregroundColor(.c2bMuted)
                    .lineLimit(1)
            }
        }
        .frame(width: avatarSize)
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.c2bTeal.opacity(0.3), Color.c2bTeal.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: avatarSize, height: avatarSize)

            Text(initials.uppercased())
                .font(.custom(.oswald.bold, size: 20))
                .foregroundColor(.c2bTeal)
        }
    }
}
