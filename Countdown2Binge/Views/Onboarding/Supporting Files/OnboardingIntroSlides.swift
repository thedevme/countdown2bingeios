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
    private var posters: [OnboardingShow] { Array(OnboardingData.popular.prefix(5)) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Color.c2bTeal.opacity(0.22), Color.c2bTeal.opacity(0.05)],
                                         startPoint: .topTrailing, endPoint: .bottomLeading))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.c2bTealLine, lineWidth: 1))
                    .frame(width: 68, height: 68)
                Image(systemName: "clock")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.c2bTealBright)
            }

            wordmark(slide?.headline ?? "COUNTDOWN2BINGE")
                .font(.custom(.oswald.bold, size: 40))
                .foregroundColor(.white)
                .padding(.top, 26)

            if let tagline = slide?.body {
                Text(tagline)
                    .font(.system(size: 16))
                    .foregroundColor(.c2bDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 290)
                    .padding(.top, 16)
            }

            Spacer(minLength: 24)

            HStack(spacing: -14) {
                ForEach(Array(posters.enumerated()), id: \.element.id) { i, show in
                    OnboardingPoster(seed: show.title, cornerRadius: 7)
                        .frame(width: 46)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#0a0a0b"), lineWidth: 1.5))
                        .rotationEffect(.degrees(Double(i - 2) * 5))
                        .offset(y: abs(Double(i - 2)) * 4)
                }
            }
            .opacity(0.5)

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 02 Problem

struct OBProblemSlide: View {
    private var slide: OnboardingSlide? { introData.problemSlide }

    var body: some View {
        OBSlide(eyebrow: slide?.label, title: slide?.headline, accent: slide?.headlineAccent, message: slide?.body) {
            VStack {
                ZStack {
                    OnboardingPoster(seed: "Shōgun", cornerRadius: 14)
                        .frame(width: 168)
                        .grayscale(1)
                        .brightness(-0.32)
                        .overlay(
                            LinearGradient(colors: [.black.opacity(0.7), .clear],
                                           startPoint: .bottom, endPoint: .center)
                        )
                    Text("SEASON ENDED")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.35), lineWidth: 2))
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
                            Text("RENEWED · NO ALERT")
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
