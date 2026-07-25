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
            label: String(localized: "timeline_now_playing"),
            tone: Color(hex: "#2dd4bf"),
            hint: String(localized: "walkthrough_airing_hint"),
            note: String(localized: "walkthrough_airing_note"),
            stepType: .bucketIntro(bucketKey: "airing")
        ),
        WalkthroughStep(
            key: "premiering",
            label: String(localized: "header_premiering_soon"),
            tone: Color(hex: "#5eead4"),
            hint: String(localized: "walkthrough_premiering_hint"),
            note: String(localized: "walkthrough_premiering_note"),
            stepType: .bucketIntro(bucketKey: "premiering")
        ),
        WalkthroughStep(
            key: "anticipated",
            label: String(localized: "header_anticipated"),
            tone: Color(hex: "#71717a"),
            hint: String(localized: "walkthrough_anticipated_hint"),
            note: String(localized: "walkthrough_anticipated_note"),
            stepType: .bucketIntro(bucketKey: "anticipated")
        ),

        // Part 2: How shows move (transitions)
        WalkthroughStep(
            key: "date-set",
            label: String(localized: "walkthrough_label_date_set"),
            tone: Color(hex: "#2dd4bf"),
            hint: String(localized: "walkthrough_date_set_hint"),
            note: String(localized: "walkthrough_date_set_note"),
            stepType: .transition(from: "anticipated", to: "premiering", showId: "stranger-things")
        ),
        WalkthroughStep(
            key: "premieres",
            label: String(localized: "walkthrough_label_premieres"),
            tone: Color(hex: "#2dd4bf"),
            hint: String(localized: "walkthrough_premieres_hint"),
            note: String(localized: "walkthrough_premieres_note"),
            stepType: .transition(from: "premiering", to: "airing", showId: "shogun")
        ),
        WalkthroughStep(
            key: "finale",
            label: String(localized: "walkthrough_label_finale"),
            tone: Color(hex: "#2dd4bf"),
            hint: String(localized: "walkthrough_finale_hint"),
            note: String(localized: "walkthrough_finale_note"),
            stepType: .transition(from: "airing", to: "binge-ready", showId: "the-last-of-us")
        )
    ]
}
