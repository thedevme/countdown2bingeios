import SwiftUI

// MARK: - Safe Array Subscript Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Timeline Walkthrough
struct TimelineWalkthrough: View {
    @Binding var isPresented: Bool
    @State private var step: Int = -1
    @State private var showOverlay: Bool = false
    @State private var showSheet: Bool = false
    @State private var flyingShows: [String: FlyingPoster] = [:]
    @State private var landedShows: Set<String> = []
    @State private var isAnimating: Bool = false

    // Part 2: Track show movements between buckets
    @State private var showLocations: [String: String] = [:]  // showId -> bucketKey
    @State private var dismissedShow: String? = nil  // Show sliding off to the right

    @Namespace private var airingNamespace
    @Namespace private var premieringNamespace
    @Namespace private var anticipatedNamespace

    // All 6 walkthrough steps
    private let walkthroughSteps = WalkthroughStep.allSteps

    // Buckets for the timeline board (Part 1)
    private let buckets: [TimelineBucket] = [
        TimelineBucket(
            key: "airing",
            label: String(localized: "timeline_now_playing"),
            tone: Color(hex: "#2dd4bf"),
            hint: String(localized: "walkthrough_airing_hint"),
            note: String(localized: "walkthrough_airing_note"),
            shows: ["vice coast", "north watch", "iron veil"],
            kind: .stack
        ),
        TimelineBucket(
            key: "premiering",
            label: String(localized: "header_premiering_soon"),
            tone: Color(hex: "#5eead4"),
            hint: String(localized: "walkthrough_premiering_hint"),
            note: String(localized: "walkthrough_premiering_note"),
            shows: ["forward hold", "echo 7"],
            kind: .premiering
        ),
        TimelineBucket(
            key: "anticipated",
            label: String(localized: "header_anticipated"),
            tone: Color(hex: "#71717a"),
            hint: String(localized: "walkthrough_anticipated_hint"),
            note: String(localized: "walkthrough_anticipated_note"),
            shows: ["blackwater point", "sentinels"],
            kind: .anticipated
        )
    ]

    private var allShows: [String] {
        buckets.flatMap { $0.shows }
    }

    private var totalSteps: Int {
        walkthroughSteps.count
    }

    // Compute effective shows for each bucket based on current state
    // Order: soonest to finish/premiere at top (index 0), latest at bottom
    private func effectiveShows(for bucketKey: String) -> [String] {
        let bucket = buckets.first { $0.key == bucketKey }
        var shows = bucket?.shows.filter { landedShows.contains($0) } ?? []

        // Remove shows that have moved AWAY from this bucket
        shows = shows.filter { showId in
            if let newLocation = showLocations[showId] {
                return newLocation == bucketKey
            }
            return true
        }

        // Add shows that have moved TO this bucket at the END (bottom)
        // New arrivals are furthest from finishing/premiering
        for (showId, location) in showLocations {
            if location == bucketKey && !shows.contains(showId) {
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
        ZStack {
            // Backdrop
            Color.black
                .opacity(showOverlay ? 0.62 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.35), value: showOverlay)

            // Bottom sheet
            VStack {
                Spacer()

                WalkthroughSheet(
                    step: $step,
                    totalSteps: totalSteps,
                    walkthroughSteps: walkthroughSteps,
                    buckets: buckets,
                    allShows: allShows,
                    landedShows: landedShows,
                    showLocations: showLocations,
                    dismissedShow: dismissedShow,
                    flyingShows: $flyingShows,
                    isAnimating: isAnimating,
                    airingNamespace: airingNamespace,
                    premieringNamespace: premieringNamespace,
                    anticipatedNamespace: anticipatedNamespace,
                    onStart: startWalkthrough,
                    onNext: nextStep,
                    onClose: closeWalkthrough
                )
                .offset(y: showSheet ? 0 : 1000)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showSheet)
            }

            // Flying posters overlay
            ForEach(Array(flyingShows.keys), id: \.self) { showId in
                if let flying = flyingShows[showId] {
                    FlyingPosterView(flying: flying, namespace: namespace(for: flying.targetBucket))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                showOverlay = true
                showSheet = true
            }
        }
    }

    private func startWalkthrough() {
        guard !isAnimating else { return }
        step = 0
        playStep(0)
    }

    private func nextStep() {
        guard !isAnimating else { return }
        if step < totalSteps - 1 {
            let nextStepIndex = step + 1
            step = nextStepIndex
            playStep(nextStepIndex)
        } else {
            closeWalkthrough()
        }
    }

    private func closeWalkthrough() {
        showSheet = false
        showOverlay = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            isPresented = false
        }
    }

    private func playStep(_ index: Int) {
        guard index < walkthroughSteps.count else { return }
        let walkthroughStep = walkthroughSteps[index]

        switch walkthroughStep.stepType {
        case .bucketIntro(let bucketKey):
            // Part 1: Shows fly into the bucket
            playBucketIntro(bucketKey: bucketKey, stepIndex: index)

        case .transition(let from, let to, let showId):
            // Part 2: A show moves between buckets
            playTransition(showId: showId, from: from, to: to, stepIndex: index)
        }
    }

    private func playBucketIntro(bucketKey: String, stepIndex: Int) {
        guard let bucket = buckets.first(where: { $0.key == bucketKey }) else {
            isAnimating = false
            return
        }

        // Clear any flying shows from previous animations
        flyingShows.removeAll()

        isAnimating = true

        for (i, showId) in bucket.shows.enumerated() {
            let delay = 0.15 + Double(i) * 0.18
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Double-check we're still on the correct step
                guard self.step == stepIndex else { return }
                self.flyPoster(showId: showId, toBucket: bucket.key)
            }
        }

        // Calculate total animation time
        let lastShowDelay = 0.15 + Double(bucket.shows.count - 1) * 0.18
        let animationDuration = 0.7
        let totalAnimationTime = lastShowDelay + animationDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationTime) {
            self.isAnimating = false
        }
    }

    private func playTransition(showId: String, from: String, to: String, stepIndex: Int) {
        isAnimating = true

        // Different animations based on step
        switch stepIndex {
        case 3:
            // A Date Is Set: Move top Anticipated show to Premiering Soon
            let topAnticipated = effectiveShows(for: "anticipated").first ?? "stranger-things"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard self.step == stepIndex else { return }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.showLocations[topAnticipated] = "premiering"
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isAnimating = false
            }

        case 4:
            // It Premieres: Move top Premiering show to Now Airing (stack grows to 4)
            let topPremiering = effectiveShows(for: "premiering").first ?? "shogun"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard self.step == stepIndex else { return }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.showLocations[topPremiering] = "airing"
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isAnimating = false
            }

        case 5:
            // The Finale Airs: Top card slides off to the right
            let topAiring = effectiveShows(for: "airing").first ?? "the-last-of-us"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard self.step == stepIndex else { return }
                withAnimation(.easeInOut(duration: 0.6)) {
                    self.dismissedShow = topAiring
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isAnimating = false
            }

        default:
            isAnimating = false
        }
    }

    private func flyPoster(showId: String, toBucket: String) {
        // Animate directly to final position with smooth deceleration
        withAnimation(.easeOut(duration: 0.7)) {
            landedShows.insert(showId)
        }
    }

    private func namespace(for bucketKey: String) -> Namespace.ID {
        switch bucketKey {
        case "airing":
            return airingNamespace
        case "premiering":
            return premieringNamespace
        case "anticipated":
            return anticipatedNamespace
        default:
            return airingNamespace
        }
    }
}
