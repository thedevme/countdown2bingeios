//
//  OnboardingIntroSlides.swift
//  Countdown2Binge
//
//  v2 onboarding — introduction (Welcome · Problem · Agitate · Solution).
//  Layout is the v2 design; all copy loads from OnboardingSlides.json +
//  Localizable.strings via OnboardingDataLoader.
//

import SwiftUI

private let introData = OnboardingDataLoader.shared

/// Color a single "2" teal in the wordmark (brand mark), else plain.
private func wordmark(_ s: String) -> Text {
    if let r = s.range(of: "2") {
        return Text(String(s[..<r.lowerBound]))
            + Text("2").foregroundColor(.c2bTeal)
            + Text(String(s[r.upperBound...]))
    }
    return Text(s)
}

// MARK: - 01 Welcome

struct OBWelcomeSlide: View {
    private var slide: OnboardingSlide? { introData.welcomeSlide }
    /// Real poster art from the asset library, used as bottom-edge texture.
    private let posters = ["shogun", "fallout", "the-last-of-us", "reacher", "outlander"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 8)

            // Greeting — localized casual greeting, all caps, with a teal period.
            (Text(String(localized: "onboarding_welcome").uppercased()) + Text(".").foregroundColor(.c2bTeal))
                .font(.custom(.oswald.bold, size: 64))
                .foregroundColor(.white)

            // Subhead
            Text(slide?.headline ?? "Let's get your shows sorted.")
                .font(.custom(.oswald.medium, size: 26))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            // Timing line — system UI face, one hierarchy step down.
            if let body = slide?.body {
                Text(body)
                    .font(.system(size: 14.5))
                    .foregroundColor(.c2bMuted)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 290, alignment: .leading)
                    .padding(.top, 14)
            }

            Spacer(minLength: 20)

            // Posters — full-color poster art as a bottom-edge band. Per the design:
            // grayscale(0.4) + brightness(0.7) per image (via colorMultiply), the
            // whole strip at 0.42 opacity, and a V-shape stagger (center highest)
            // with an 8px overlap. Full-bleed, cropped at the bottom edge.
            HStack(alignment: .top, spacing: -8) {
                ForEach(Array(posters.enumerated()), id: \.offset) { i, name in
                    Image(name)
                        .resizable()
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        .frame(width: 120, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .grayscale(0.4)
                        .colorMultiply(Color(white: 0.7))          // ≈ brightness(0.7)
                        .padding(.top, CGFloat(abs(i - 2)) * 12)   // V-stagger: 24,12,0,12,24
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 185, alignment: .top)
            .clipped()
            .opacity(0.42)                       // container opacity
            .padding(.horizontal, -22)           // full-bleed past OBShell's padding

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 02 Problem

struct OBProblemSlide: View {
    private var slide: OnboardingSlide? { introData.problemSlide }

    var body: some View {
        OBSlide(eyebrow: slide?.label, title: slide?.headline, accent: slide?.headlineAccent, message: slide?.body) {
            VStack {
                ZStack {
                    Image("stranger-things")
                        .resizable()
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        .frame(width: 168, height: 252)
                        .grayscale(1)
                        .overlay(Color.black.opacity(0.1))   // darkener at 10%
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    Text(String(localized: "onboarding_season_ended"))
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .tracking(1.5)
                        .foregroundColor(Color(hex: "#E5484D"))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#E5484D").opacity(0.85), lineWidth: 2))
                        .rotationEffect(.degrees(-11))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 26)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - 03 Agitate

struct OBAgitateSlide: View {
    private var slide: OnboardingSlide? { introData.agitateSlide }
    private let days: [(String, Bool)] = [("MON", false), ("TUE", true), ("WED", false), ("THU", false), ("FRI", false)]

    var body: some View {
        OBSlide(eyebrow: slide?.label, title: slide?.headline, accent: slide?.headlineAccent, message: slide?.body) {
            VStack(spacing: 0) {
                ForEach(days, id: \.0) { day, hit in
                    HStack(spacing: 12) {
                        Text(day)
                            .font(.custom(.jetbrains.regular, size: 9))
                            .tracking(1.08)
                            .foregroundColor(hit ? .c2bDim : .white.opacity(0.18))
                            .frame(width: 34, alignment: .leading)
                        Rectangle()
                            .fill(hit ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
                            .frame(height: 1)
                        if hit {
                            Text(String(localized: "onboarding_renewed_no_alert"))
                                .font(.custom(.jetbrains.regular, size: 8))
                                .tracking(0.8)
                                .foregroundColor(.c2bMuted)
                        } else {
                            Text("—")
                                .font(.custom(.jetbrains.regular, size: 8))
                                .foregroundColor(.white.opacity(0.14))
                        }
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1) }
                }
            }
            .frame(maxWidth: 280)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - 04 Solution

struct OBSolutionSlide: View {
    private var slide: OnboardingSlide? { introData.solutionSlide }

    private var rows: [(String, Color, Bool)] {
        [(String(localized: "onboarding_solution_renewed"), .c2bTealBright, true),
         (String(localized: "onboarding_solution_cancelled"), .c2bMuted, false),
         (String(localized: "onboarding_solution_premiere"), .c2bTeal, true)]
    }

    var body: some View {
        OBSlide(eyebrow: slide?.label, title: slide?.headline, accent: slide?.headlineAccent, message: slide?.body) {
            VStack(spacing: 10) {
                ForEach(rows, id: \.0) { label, color, teal in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(color)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(teal ? Color.c2bTeal.opacity(0.15) : Color.white.opacity(0.07), lineWidth: 4))
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.c2bText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.c2bTealBright)
                    }
                    .padding(.horizontal, 15).padding(.vertical, 14)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(.vertical, 24)
        }
    }
}
