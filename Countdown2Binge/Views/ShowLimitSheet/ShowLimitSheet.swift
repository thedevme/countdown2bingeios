//
//  ShowLimitSheet.swift
//  Countdown2Binge
//
//  The step between "Follow was refused" and the paywall.
//
//  Hitting the free-tier cap used to throw the full paywall up with no
//  explanation — from the user's side they tapped Follow and got a sales page,
//  with no idea why the show wasn't added. This says what happened and what
//  their options are first; the paywall is one deliberate tap further on.
//
//  Deliberately short: it's an explanation, not a pitch. The pitch is the
//  paywall's job.
//

import SwiftUI

struct ShowLimitSheet: View {
    /// How many shows the free tier allows.
    let limit: Int
    /// Posters of the shows already followed — the ones taking up the slots.
    /// Showing their own library is more legible than an abstract lock: the
    /// answer to "why can't I add this?" is right there on screen.
    let posterURLs: [URL?]
    /// Show the paywall. The sheet dismisses itself first.
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    /// The slots in use, fanned like the timeline's hero stack. Falls back to
    /// a lock when there's nothing to show — the sheet can be reached with an
    /// empty library during a grace period.
    @ViewBuilder
    private var posterRow: some View {
        if posterURLs.isEmpty {
            Image(systemName: "lock.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.c2bTealBright)
                .frame(width: 52, height: 52)
                .background(Color.c2bTeal.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.c2bTealLine, lineWidth: 1)
                )
        } else {
            HStack(spacing: -14) {
                ForEach(Array(posterURLs.prefix(limit).enumerated()), id: \.offset) { index, url in
                    PosterView(url: url, width: 62, cornerRadius: 9)
                        .frame(width: 62, height: 93)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color(hex: "#0e0e0f"), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                        .rotationEffect(.degrees(Double(index - (posterURLs.prefix(limit).count - 1) / 2) * 5))
                        .zIndex(Double(index))
                }
            }
            .padding(.top, 4)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 22)

            posterRow
                .padding(.bottom, 20)

            Text(String(localized: "limit_title \(limit)"))
                .font(.custom(.oswald.bold, size: 22))
                .tracking(0.44)
                .foregroundColor(.c2bText)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            Text(String(localized: "limit_body \(limit)"))
                .font(.system(size: 14))
                .foregroundColor(.c2bDim)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 26)

            Button(action: onUpgrade) {
                Text(String(localized: "limit_upgrade"))
                    .font(.custom(.oswald.bold, size: 16))
                    .tracking(0.48)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bOnTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.c2bTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Button(action: onDismiss) {
                Text(String(localized: "limit_not_now"))
                    .font(.custom(.jetbrains.regular, size: 10))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.hidden)
        // Paints the sheet itself — corners and safe area included — rather than
        // just the content box, which is what left a pale band along the bottom.
        .presentationBackground(Color(hex: "#0e0e0f"))
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            ShowLimitSheet(limit: 3, posterURLs: [nil, nil, nil], onUpgrade: {}, onDismiss: {})
        }
}
