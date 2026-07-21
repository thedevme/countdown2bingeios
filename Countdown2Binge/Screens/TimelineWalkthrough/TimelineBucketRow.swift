import SwiftUI

// MARK: - Dismissing Card Animation
struct DismissingCard: View {
    let showId: String
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Image(showId)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 118, height: 176)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.7), radius: 20, x: 0, y: 12)
            .offset(x: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6)) {
                    offset = 350
                    opacity = 0
                }
            }
    }
}

struct TimelineBucketRow: View {
    let bucket: TimelineBucket
    let isActive: Bool
    let isDone: Bool
    let shows: [String]  // Effective shows for this bucket
    let dismissedShow: String?  // Show being dismissed (slides off right)
    let namespace: Namespace.ID

    private var isOn: Bool { isActive || isDone }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            // Spacer to align with label bullet
            Color.clear
                .frame(width: 12, height: 1)

            // Content
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10) {
                    if shows.isEmpty {
                        // Empty state
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                style: StrokeStyle(lineWidth: 1.5, dash: [5])
                            )
                            .foregroundColor(isActive ? bucket.tone.opacity(0.40) : Color.white.opacity(0.08))
                            .frame(height: 60)
                            .overlay(
                                Text(isActive ? "LANDING…" : "EMPTY")
                                    .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                                    .foregroundColor(Color(hex: "#52525b"))
                                    .textCase(.uppercase)
                                    .tracking(1.6)
                            )
                    } else {
                        // Landed shows
                        switch bucket.kind {
                        case .stack:
                            AiringStack(shows: shows, bucketKey: bucket.key, namespace: namespace)
                                .frame(width: 180)
                        case .premiering:
                            VStack(spacing: 12) {
                                ForEach(shows, id: \.self) { showId in
                                    PremieringCard(showId: showId, bucketKey: bucket.key, namespace: namespace)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            }
                        case .anticipated:
                            VStack(spacing: 12) {
                                ForEach(shows, id: \.self) { showId in
                                    AnticipatedCard(showId: showId, bucketKey: bucket.key, namespace: namespace)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            }
                        }
                    }
                }

                // Dismissed show sliding off to the right
                if let dismissed = dismissedShow, bucket.kind == .stack {
                    DismissingCard(showId: dismissed)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: shows)
    }
}

