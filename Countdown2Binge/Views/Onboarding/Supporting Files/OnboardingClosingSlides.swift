//
//  OnboardingClosingSlides.swift
//  Countdown2Binge
//
//  v2 onboarding — Notif priming (+ system permission) · Summary · Commitment ·
//  Price anchor. Copy loads from OnboardingSlides.json + Localizable.strings.
//

import SwiftUI

private let closingData = OnboardingDataLoader.shared

// MARK: - 14 Notification priming

struct OBNotifPrimeSlide: View {
    private var slide: OnboardingSlide? { closingData.notifPrimingSlide }

    var body: some View {
        OBSlide(eyebrow: slide?.label, title: slide?.headline, accent: slide?.headlineAccent, message: slide?.body) {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.c2bTeal)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.system(size: 19))
                            .foregroundColor(.c2bOnTeal)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "onboarding_notif_example_title"))
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                    Text(String(localized: "onboarding_notif_example_body"))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer(minLength: 0)
                Text("now")
                    .font(.custom(.jetbrains.regular, size: 8.5))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(15)
            .background(Color(hex: "#28282c").opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 20, y: 16)
            .padding(.vertical, 26)
        }
    }
}

// MARK: - 15 System permission (native-style alert — mirrors the iOS dialog)

struct OBSystemPermission: View {
    let onAllow: () -> Void
    let onDeny: () -> Void

    private let ios = Color(hex: "#0A84FF")

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(String(localized: "onboarding_notif_perm_title"))
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text(String(localized: "onboarding_notif_perm_body"))
                        .font(.system(size: 12.5))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 16)

                Divider().overlay(Color.white.opacity(0.22))

                HStack(spacing: 0) {
                    Button(action: onDeny) {
                        Text(String(localized: "onboarding_notif_perm_deny")).font(.system(size: 16)).foregroundColor(ios)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    Divider().overlay(Color.white.opacity(0.22)).frame(height: 44)
                    Button(action: onAllow) {
                        Text(String(localized: "onboarding_notif_perm_allow")).font(.system(size: 16, weight: .semibold)).foregroundColor(ios)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 270)
            .background(Color(hex: "#2e2e30").opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - 16 Journey summary

struct OBSummarySlide: View {
    let count: Int
    private var slide: OnboardingSlide? { closingData.journeySummarySlide }
    private var next: OnboardingShow? { OnboardingData.popular.first }

    private var bodyText: String {
        guard let body = slide?.body else { return "" }
        return String(format: body, count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label = slide?.label {
                Text(label)
                    .font(.custom(.jetbrains.regular, size: 10))
                    .tracking(2.0)
                    .foregroundColor(.c2bTeal)
            }

            Spacer(minLength: 20)

            Text("\(Text((slide?.headline ?? "") + " "))\(Text(slide?.headlineAccent ?? "").foregroundColor(.c2bTeal))")
                .font(.custom(.oswald.bold, size: 44))
                .foregroundColor(.white)

            Text(bodyText)
                .font(.system(size: 15))
                .foregroundColor(.c2bDim)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)

            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.c2bTealBright)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "onboarding_journey_next_update"))
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(1.19)
                        .foregroundColor(.c2bTealBright)
                    Text(next.map { "\($0.title), soon" } ?? "As soon as a date is announced")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.c2bText)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .background(LinearGradient(colors: [Color.c2bTeal.opacity(0.12), Color.c2bTeal.opacity(0.02)],
                                       startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.c2bTealLine, lineWidth: 1))
            .padding(.top, 22)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 17 Commitment

struct OBCommitmentSlide: View {
    @Binding var answer: String?
    private var question: OnboardingQuestion? { closingData.commitmentQuestion }

    var body: some View {
        if let q = question {
            OBSlide(eyebrow: String(localized: "onboarding_commitment_label"),
                    title: q.headline, accent: q.headlineAccent) {
                VStack(spacing: 9) {
                    ForEach(q.options) { option in
                        OBRadioRow(text: option.label, selected: answer == option.id) { answer = option.id }
                    }
                }
                .padding(.top, 26)
            }
        }
    }
}

// MARK: - 18 Price anchor

struct OBPriceAnchorSlide: View {
    let services: Set<String>
    private var slide: OnboardingSlide? { closingData.priceAnchorSlide }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label = slide?.label {
                Text(label)
                    .font(.custom(.jetbrains.regular, size: 10))
                    .tracking(2.0)
                    .foregroundColor(.c2bTeal)
            }

            Spacer(minLength: 20)

            Text("\(Text((slide?.headline ?? "") + "\n"))\(Text(slide?.headlineAccent ?? "").foregroundColor(.c2bTeal))\(Text("\n" + (slide?.statLabel ?? "")))")
                .font(.custom(.oswald.bold, size: 36))
                .foregroundColor(.white)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if let body = slide?.body {
                Text(body)
                    .font(.system(size: 16))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.system(size: 13)).foregroundColor(.c2bTealBright)
                    }
                }
                Text(String(localized: "onboarding_price_testimonial"))
                    .font(.system(size: 13.5))
                    .italic()
                    .foregroundColor(.c2bDim)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 17).padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.top, 26)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
