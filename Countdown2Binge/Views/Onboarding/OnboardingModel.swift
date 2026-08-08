//
//  OnboardingModel.swift
//  Countdown2Binge
//
//  DESIGN-ONLY data + shared chrome for the v2 onboarding flow.
//  Ported from c2b-onboarding-v2.jsx / c2b-onboarding.jsx. Sample data drives the
//  design; convert to your real models when wiring up (OnboardingShow.summary).
//

import SwiftUI

// MARK: - Sample show model

struct OnboardingShow: Identifiable, Hashable {
    let id: Int
    let title: String
    let platform: String
    let seasonLabel: String

    /// Bridge to the app's lightweight model for `onComplete`.
    var summary: ShowSummary {
        ShowSummary(id: id, name: title, overview: nil, posterPath: nil,
                    backdropPath: nil, firstAirDate: nil, voteAverage: nil, genreIds: nil)
    }
}

enum OnboardingData {
    static let popular: [OnboardingShow] = [
        .init(id: 1, title: "Severance", platform: "APPLE TV+", seasonLabel: "S2"),
        .init(id: 2, title: "Shōgun", platform: "HULU", seasonLabel: "S1"),
        .init(id: 3, title: "The Last of Us", platform: "MAX", seasonLabel: "S2"),
        .init(id: 4, title: "Fallout", platform: "PRIME", seasonLabel: "S1"),
        .init(id: 5, title: "Reacher", platform: "PRIME", seasonLabel: "S3"),
        .init(id: 6, title: "Wednesday", platform: "NETFLIX", seasonLabel: "S2"),
        .init(id: 7, title: "The Bear", platform: "HULU", seasonLabel: "S4"),
        .init(id: 8, title: "Stranger Things", platform: "NETFLIX", seasonLabel: "S5"),
        .init(id: 9, title: "The Witcher", platform: "NETFLIX", seasonLabel: "S4"),
        .init(id: 10, title: "Outlander", platform: "STARZ", seasonLabel: "S8"),
        .init(id: 11, title: "Daredevil: Born Again", platform: "DISNEY+", seasonLabel: "S2"),
        .init(id: 12, title: "True Detective", platform: "MAX", seasonLabel: "S4"),
    ]

    static let genres = [
        "Sci-Fi & Fantasy", "Drama", "Comedy", "Crime", "Thriller", "Documentary",
        "Animation", "Reality", "Action", "Mystery", "Horror", "Family",
    ]

    struct Service: Identifiable, Hashable {
        let name: String
        let colorHex: String
        let monthly: Double
        var id: String { name }
        var isLight: Bool { name == "Apple TV+" || name == "Peacock" }
    }

    static let services: [Service] = [
        .init(name: "Netflix", colorHex: "#E50914", monthly: 15.49),
        .init(name: "Max", colorHex: "#5A35E0", monthly: 16.99),
        .init(name: "Hulu", colorHex: "#1CE783", monthly: 18.99),
        .init(name: "Disney+", colorHex: "#1FA2FF", monthly: 15.99),
        .init(name: "Apple TV+", colorHex: "#9aa0a6", monthly: 12.99),
        .init(name: "Prime Video", colorHex: "#1FB6FF", monthly: 8.99),
        .init(name: "Paramount+", colorHex: "#0064FF", monthly: 12.99),
        .init(name: "Peacock", colorHex: "#F5C518", monthly: 13.99),
        .init(name: "Other", colorHex: "#52525b", monthly: 0),
    ]

    static let behaviorOptions = [
        "A friend mentions it months later",
        "I randomly notice it on the home screen",
        "I google it every few weeks",
        "Honestly? I don't. I just lose track.",
    ]

    static let tiredOptions = [
        "Extremely. I've lost track of at least three.",
        "Pretty tired.",
        "It happens sometimes.",
    ]

    /// Estimated monthly spend from picked services (nil → only "Other").
    static func monthlySpend(for picked: Set<String>) -> Int? {
        let known = services.filter { picked.contains($0.name) && $0.monthly > 0 }
        guard !known.isEmpty else { return nil }
        return Int(known.reduce(0) { $0 + $1.monthly }.rounded())
    }

    // Pricing (android handoff §6)
    struct PlanTier: Identifiable, Hashable {
        let id: String
        let name: String
        let price: String
        let per: String
        let note: String
        let best: Bool
        let feats: String
    }

    static func planTiers(showCount: Int) -> [PlanTier] {
        [
            .init(id: "yearly", name: "Yearly", price: "$9.99", per: "/yr", note: "7-day free trial · then $9.99/yr",
                  best: true, feats: "Unlimited shows · sync · alerts"),
            .init(id: "monthly", name: "Monthly", price: "$1.49", per: "/mo", note: "Billed monthly",
                  best: false, feats: "Unlimited shows · sync · alerts"),
            .init(id: "lifetime", name: "Lifetime", price: "$29.99", per: " once", note: "One-time · yours forever",
                  best: false, feats: "Unlimited shows · sync · alerts"),
            .init(id: "free", name: "Free", price: "$0", per: "", note: "Up to 3 shows · no alerts or sync",
                  best: false, feats: "Track your \(showCount) shows, basic timeline"),
        ]
    }
}

// MARK: - Poster placeholder (deterministic gradient, no network)

struct OnboardingPoster: View {
    let seed: String
    var cornerRadius: CGFloat = 11

    var body: some View {
        ZStack {
            LinearGradient(colors: LandscapeBackdrop.palette(for: seed),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Shared slide chrome (V2Slide)

/// Eyebrow + big display title (optional teal accent line) + body, then content.
struct OBSlide<Content: View>: View {
    var eyebrow: String? = nil
    var title: String? = nil
    var accent: String? = nil
    var message: String? = nil
    var titleSize: CGFloat = 38
    var center: Bool = false
    @ViewBuilder var content: () -> Content

    init(eyebrow: String? = nil, title: String? = nil, accent: String? = nil,
         message: String? = nil, titleSize: CGFloat = 38, center: Bool = false,
         @ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.eyebrow = eyebrow
        self.title = title
        self.accent = accent
        self.message = message
        self.titleSize = titleSize
        self.center = center
        self.content = content
    }

    private var titleText: Text {
        var t = Text(title ?? "")
        if let accent {
            t = t + Text("\n") + Text(accent).foregroundColor(.c2bTeal)
        }
        return t
    }

    var body: some View {
        VStack(alignment: center ? .center : .leading, spacing: 0) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.custom(.jetbrains.regular, size: 10))
                    .tracking(2.0)
                    .foregroundColor(.c2bTeal)
            }
            if title != nil {
                titleText
                    .font(.custom(.oswald.bold, size: titleSize))
                    .foregroundColor(.white)
                    .lineSpacing(2)
                    .multilineTextAlignment(center ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            if let message {
                Text(message)
                    .font(.system(size: 14.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .multilineTextAlignment(center ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: center ? .center : .leading)
    }
}
