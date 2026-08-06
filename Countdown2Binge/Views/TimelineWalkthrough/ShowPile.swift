import SwiftUI

struct ShowPile: View {
    let allShows: [String]
    let landedShows: Set<String>
    let flyingShows: [String: FlyingPoster]
    let buckets: [TimelineBucket]
    let airingNamespace: Namespace.ID
    let premieringNamespace: Namespace.ID
    let anticipatedNamespace: Namespace.ID

    private func namespace(for showId: String) -> Namespace.ID {
        for bucket in buckets {
            if bucket.shows.contains(showId) {
                switch bucket.key {
                case "airing":
                    return airingNamespace
                case "premiering":
                    return premieringNamespace
                case "anticipated":
                    return anticipatedNamespace
                default:
                    break
                }
            }
        }
        return airingNamespace
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                // Vertical label
                Text("timeline_your_shows")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.caption))
                    .foregroundColor(Color(hex: "#71717a"))
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 48, height: 20)

                // Posters
                ForEach(allShows, id: \.self) { showId in
                    let isGone = landedShows.contains(showId) || flyingShows[showId] != nil

                    if flyingShows[showId] == nil {
                        Image(showId)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .matchedGeometryEffect(id: showId, in: namespace(for: showId))
                            .opacity(isGone ? 0.1 : 1.0)
                            .animation(.easeOut(duration: 0.3), value: isGone)
                    } else {
                        // Placeholder to maintain spacing
                        Color.clear
                            .frame(width: 32, height: 48)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .stroke(
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
                .foregroundColor(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.bottom, 10),
            alignment: .bottom
        )
    }
}
