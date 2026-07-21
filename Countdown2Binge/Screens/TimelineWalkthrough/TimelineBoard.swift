// NOTE: Parent animation affecting bucket 0 label must be commented out in the coordinator or parent view. No animation is present in TimelineBoard itself.

import SwiftUI

struct TimelineBoard: View {
    let buckets: [TimelineBucket]
    let step: Int
    let landedShows: Set<String>
    let showLocations: [String: String]  // Track where shows have moved
    let dismissedShow: String?  // Show sliding off to the right
    let airingNamespace: Namespace.ID
    let premieringNamespace: Namespace.ID
    let anticipatedNamespace: Namespace.ID

    // Compute effective shows for each bucket based on current state
    // Order: soonest to finish/premiere at top (index 0), latest at bottom
    private func effectiveShows(for bucket: TimelineBucket) -> [String] {
        var shows = bucket.shows.filter { landedShows.contains($0) }

        // Remove shows that have moved AWAY from this bucket
        shows = shows.filter { showId in
            if let newLocation = showLocations[showId] {
                return newLocation == bucket.key
            }
            return true
        }

        // Add shows that have moved TO this bucket at the END (bottom)
        // New arrivals are furthest from finishing/premiering
        for (showId, location) in showLocations {
            if location == bucket.key && !shows.contains(showId) {
                shows.append(showId)  // Add to end (bottom of stack)
            }
        }

        // Remove dismissed show
        if let dismissed = dismissedShow {
            shows.removeAll { $0 == dismissed }
        }

        return shows
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Vertical timeline line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#2dd4bf"),
                            Color(hex: "#5eead4"),
                            Color(hex: "#71717a").opacity(0.3),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .padding(.leading, 5)

            VStack {
                TimelineBucketLabel(
                    label: buckets[0].label,
                    tone: buckets[0].tone,
                    isActive: 0 == step,
                    isDone: 0 < step
                )
            }


            // Buckets
            VStack(spacing: 20) {
                // Bucket 0: Now Airing
                VStack(alignment: .leading, spacing: 10) {

                    TimelineBucketRow(
                        bucket: buckets[0],
                        isActive: 0 == step,
                        isDone: 0 < step,
                        shows: effectiveShows(for: buckets[0]),
                        dismissedShow: dismissedShow,
                        namespace: airingNamespace
                    )
                }
                .padding(.top, 30)

                // Bucket 1: Premiering Soon
                VStack(alignment: .leading, spacing: 10) {
                    TimelineBucketLabel(
                        label: buckets[1].label,
                        tone: buckets[1].tone,
                        isActive: 1 == step,
                        isDone: 1 < step
                    )
                    .id("section-premiering")

                    TimelineBucketRow(
                        bucket: buckets[1],
                        isActive: 1 == step,
                        isDone: 1 < step,
                        shows: effectiveShows(for: buckets[1]),
                        dismissedShow: nil,
                        namespace: premieringNamespace
                    )
                }

                // Bucket 2: Anticipated
                VStack(alignment: .leading, spacing: 10) {
                    TimelineBucketLabel(
                        label: buckets[2].label,
                        tone: buckets[2].tone,
                        isActive: 2 == step,
                        isDone: 2 < step
                    )
                    .id("section-anticipated")

                    TimelineBucketRow(
                        bucket: buckets[2],
                        isActive: 2 == step,
                        isDone: 2 < step,
                        shows: effectiveShows(for: buckets[2]),
                        dismissedShow: nil,
                        namespace: anticipatedNamespace
                    )
                }
            }
        }
        .padding(.vertical, 12)
    }
}
