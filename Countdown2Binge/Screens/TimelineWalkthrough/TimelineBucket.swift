import SwiftUI

struct TimelineBucket {
    let key: String
    let label: String
    let tone: Color
    let hint: String
    let note: String
    let shows: [String]
    let kind: BucketKind

    enum BucketKind {
        case premiering
        case stack
        case anticipated
    }
}

// MARK: - Walkthrough Step (for 6-step tour)

struct WalkthroughStep {
    let key: String
    let label: String
    let tone: Color
    let hint: String
    let note: String
    let stepType: StepType

    enum StepType {
        case bucketIntro(bucketKey: String)  // Steps 0-2: shows fly into bucket
        case transition(from: String, to: String, showId: String)  // Steps 3-5: show moves between buckets
    }
}

extension WalkthroughStep {
    static let allSteps: [WalkthroughStep] = [
        // Part 1: The three stages (shows fly in)
        WalkthroughStep(
            key: "airing",
            label: "NOW AIRING",
            tone: Color(hex: "#2dd4bf"),
            hint: "Shows releasing new episodes right now, week to week. The one closest to its finale sits on top — that's what you'll binge next.",
            note: "As each finale airs, the show drops to Binge Ready and the next rises to the top.",
            stepType: .bucketIntro(bucketKey: "airing")
        ),
        WalkthroughStep(
            key: "premiering",
            label: "PREMIERING SOON",
            tone: Color(hex: "#5eead4"),
            hint: "Shows with a locked premiere date, counting down day by day until the new season starts releasing.",
            note: "The moment a season premieres, it moves up into Now Airing.",
            stepType: .bucketIntro(bucketKey: "premiering")
        ),
        WalkthroughStep(
            key: "anticipated",
            label: "ANTICIPATED",
            tone: Color(hex: "#71717a"),
            hint: "Renewed shows that don't have a release date yet. They wait quietly at the bottom so you never lose track of them.",
            note: "As soon as a date is announced, they jump to Premiering Soon.",
            stepType: .bucketIntro(bucketKey: "anticipated")
        ),

        // Part 2: How shows move (transitions)
        WalkthroughStep(
            key: "date-set",
            label: "A DATE IS SET",
            tone: Color(hex: "#2dd4bf"),
            hint: "The Bear just got a premiere date. It moves up out of Anticipated into Premiering Soon and starts counting down.",
            note: "Anticipated → Premiering Soon",
            stepType: .transition(from: "anticipated", to: "premiering", showId: "stranger-things")
        ),
        WalkthroughStep(
            key: "premieres",
            label: "IT PREMIERES",
            tone: Color(hex: "#2dd4bf"),
            hint: "Shogun just premiered. It climbs into Now Airing and joins the stack while new episodes release each week.",
            note: "Premiering Soon → Now Airing",
            stepType: .transition(from: "premiering", to: "airing", showId: "shogun")
        ),
        WalkthroughStep(
            key: "finale",
            label: "THE FINALE AIRS",
            tone: Color(hex: "#2dd4bf"),
            hint: "The Last of Us's finale aired — the full season is now Binge Ready. Its next season cycles back down to Anticipated until a new date is announced.",
            note: "Now Airing → Binge Ready → next season to Anticipated",
            stepType: .transition(from: "airing", to: "binge-ready", showId: "the-last-of-us")
        )
    ]
}
