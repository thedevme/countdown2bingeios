//
//  OnboardingSelectionSlides.swift
//  Countdown2Binge
//
//  v2 onboarding — Add Shows · Four States · Review prompt.
//  Copy loads from Localizable.strings (Add Shows keys) and OnboardingSlides.json
//  (buckets, review) via OnboardingDataLoader.
//

import SwiftUI
import Combine

private let selectionData = OnboardingDataLoader.shared

// MARK: - 10 Add your shows (no JSON slide entry — uses localized keys directly)

struct OBAddShowsSlide: View {
    @Binding var followed: Set<Int>
    @State private var query = ""

    private var results: [OnboardingShow] {
        query.isEmpty ? OnboardingData.popular
            : OnboardingData.popular.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 13), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "onboarding_add_shows_label_v2"))
                .font(.custom(.jetbrains.regular, size: 10))
                .tracking(2.0)
                .foregroundColor(.c2bTeal)

            (Text(String(localized: "onboarding_add_shows_title_v2") + " ")
                + Text(String(localized: "onboarding_add_shows_accent")).foregroundColor(.c2bTeal))
                .font(.custom(.oswald.bold, size: 36))
                .foregroundColor(.white)
                .padding(.top, 10)

            Text(String(localized: "onboarding_add_shows_desc_v2"))
                .font(.system(size: 14))
                .foregroundColor(.c2bDim)
                .lineSpacing(3)
                .padding(.top, 8)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(.c2bMuted)
                TextField("", text: $query, prompt: Text("Search shows…").foregroundColor(.c2bMuted))
                    .font(.system(size: 15))
                    .foregroundColor(.c2bText)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 13) {
                ForEach(results) { show in
                    OBAddShowTile(show: show, following: followed.contains(show.id)) {
                        toggle(show.id)
                    }
                }
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggle(_ id: Int) {
        if followed.contains(id) { followed.remove(id) } else { followed.insert(id) }
    }
}

private struct OBAddShowTile: View {
    let show: OnboardingShow
    let following: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                OnboardingPoster(seed: show.title, cornerRadius: 11)
                    .overlay(alignment: .topLeading) {
                        if following {
                            ZStack {
                                Circle().fill(Color.c2bTeal).frame(width: 24, height: 24)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(.c2bOnTeal)
                            }
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            .padding(7)
                        }
                    }
                Text(show.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)
                    .padding(.top, 9)
                Text(following ? "✓ " + String(localized: "onboarding_following") : "TAP TO FOLLOW")
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(0.72)
                    .foregroundColor(following ? .c2bTealBright : .c2bMuted)
                    .padding(.top, 4)
            }
            .padding(9)
            .background(following ? Color.c2bTeal.opacity(0.06) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(following ? Color.c2bTealLine : Color.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 12 Four states

struct OBBucketsSlide: View {
    private var slide: OnboardingSlide? { selectionData.bucketsSlide }
    private var buckets: [BucketInfo] { selectionData.allBuckets }

    @State private var lit = 3
    private let timer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    private func color(for id: String) -> Color {
        switch id {
        case "bingeReady": return .c2bTealBright
        case "nowAiring": return .c2bTeal
        case "premieringSoon": return Color.c2bTeal.opacity(0.6)
        default: return Color.white.opacity(0.34)
        }
    }

    var body: some View {
        OBSlide(eyebrow: slide?.label, title: slide?.headline, accent: slide?.headlineAccent) {
            VStack(spacing: 9) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { i, bucket in
                    let on = lit == i
                    let tint = color(for: bucket.id)
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(tint)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().stroke(on ? Color.c2bTeal.opacity(0.16) : Color.clear, lineWidth: 5))
                            .padding(.top, 4)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(bucket.title)
                                .font(.custom(.oswald.bold, size: 18))
                                .foregroundColor(bucket.id == "anticipated" ? .c2bText : tint)
                            Text(bucket.description)
                                .font(.system(size: 12.5))
                                .foregroundColor(.c2bMuted)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 15).padding(.vertical, 13)
                    .background(on ? Color.c2bTeal.opacity(0.07) : Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1))
                    .animation(.easeInOut(duration: 0.4), value: lit)
                }
            }
            .padding(.top, 22)
        }
        .onReceive(timer) { _ in
            if !buckets.isEmpty { lit = (lit - 1 + buckets.count) % buckets.count }
        }
    }
}

// MARK: - 13 Review prompt

struct OBReviewSlide: View {
    let count: Int
    private var slide: OnboardingSlide? { selectionData.reviewPromptSlide }

    var body: some View {
        VStack(spacing: 0) {
            if let label = slide?.label {
                Text(label)
                    .font(.custom(.jetbrains.regular, size: 10))
                    .tracking(2.0)
                    .foregroundColor(.c2bTeal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 20)

            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.c2bTealBright)
                }
            }
            .padding(.bottom, 22)

            (Text((slide?.headline ?? "") + "\n") + Text(slide?.headlineAccent ?? "").foregroundColor(.c2bTeal))
                .font(.custom(.oswald.bold, size: 34))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            if let body = slide?.body {
                Text(body)
                    .font(.system(size: 14.5))
                    .foregroundColor(.c2bDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 300)
                    .padding(.top, 18)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}
