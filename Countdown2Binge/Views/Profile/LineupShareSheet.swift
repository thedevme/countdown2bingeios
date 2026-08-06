//
//  LineupShareSheet.swift
//  Countdown2Binge
//
//  Share sheet for sharing lineup with social media.
//

import SwiftUI

struct LineupShareSheet: View {
    let profile: UserProfile
    let shows: [Series]
    let isPremium: Bool
    var onClose: () -> Void = {}

    @State private var isPresented = false

    private var topShows: [Series] {
        Array(shows.prefix(6))
    }

    private var nextBingeShow: Series? {
        // Find the next show that's anticipated or airing
        shows.first { show in
            let state = show.showState
            return state == .anticipated || state == .airing
        }
    }

    private var daysToNextBinge: Int? {
        guard let nextShow = nextBingeShow else { return nil }
        // For airing shows, use days until finale (binge ready)
        // For anticipated shows, use days until premiere
        return nextShow.daysUntilFinale ?? nextShow.daysUntilPremiere
    }

    var body: some View {
        ZStack {
            // Backdrop - fades in separately
            Color.black.opacity(isPresented ? 0.72 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.2), value: isPresented)
                .onTapGesture { dismissSheet() }

            VStack {
                Spacer()

                if isPresented {
                    VStack(spacing: 0) {
                        // Drag handle
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 4)
                            .padding(.top, 10)
                            .padding(.bottom, 18)

                        // Shareable card
                        shareableCard
                            .padding(.horizontal, 20)

                        // Share destinations
                        shareDestinations
                            .padding(.top, 20)
                            .padding(.horizontal, 20)

                        // Cancel button
                        Button(action: { dismissSheet() }) {
                            Text("button_cancel")
                                .font(.custom(.oswald.bold, size: 14))
                                .tracking(0.6)
                                .textCase(.uppercase)
                                .foregroundColor(.c2bDim)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.clear)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 26)
                    }
                    .background(Color(hex: "#0e0e0f"))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            topTrailingRadius: 24
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            topTrailingRadius: 24
                        )
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
        }
        .onAppear {
            isPresented = true
        }
    }

    private func dismissSheet() {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onClose()
        }
    }

    private var shareableCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ProfileAvatar(profile: profile, size: 42)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(profile.name)'s lineup")
                        .font(.custom(.oswald.bold, size: 19))
                        .foregroundColor(.white)

                    Text("\(shows.count) \(String(localized: "share_seasons_tracked"))")
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bMuted)
                }

                Spacer()

                // C2B badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.c2bTealBright)
                        .frame(width: 5, height: 5)

                    Text("C2B")
                        .font(.custom(.jetbrains.bold, size: 7.5))
                        .tracking(1.2)
                        .foregroundColor(.c2bTealBright)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.c2bTeal.opacity(0.12))
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(Color.c2bTealLine, lineWidth: 1)
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Poster grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 6), spacing: 5) {
                ForEach(topShows, id: \.id) { show in
                    posterImage(for: show)
                }

                // Fill empty slots
                ForEach(0..<max(0, 6 - topShows.count), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.c2bSurface)
                        .aspectRatio(2/3, contentMode: .fit)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            // Next binge countdown
            if let nextShow = nextBingeShow, let days = daysToNextBinge {
                HStack(spacing: 11) {
                    Text("\(days)")
                        .font(.custom(.oswald.bold, size: 30))
                        .foregroundColor(.c2bTealBright)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("share_days_to_binge")
                            .font(.custom(.jetbrains.regular, size: 8.5))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundColor(.c2bTeal)

                        Text(nextShow.name)
                            .font(.system(size: 12))
                            .foregroundColor(.c2bDim)
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(Color.white.opacity(0.03))
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .background(Color(hex: "#0b0b0c"))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 22, y: 16)
    }

    private func posterImage(for show: Series) -> some View {
        return AsyncImage(url: show.posterURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Rectangle()
                    .fill(Color.c2bSurface)
            }
        }
        .aspectRatio(2/3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var shareDestinations: some View {
        HStack(spacing: 10) {
            ShareDestinationButton(
                label: "Messages",
                color: Color(hex: "#34C759"),
                icon: "message.fill"
            ) {
                dismissSheet()
            }

            ShareDestinationButton(
                label: "Instagram",
                color: Color(hex: "#E1306C"),
                icon: "camera.fill"
            ) {
                dismissSheet()
            }

            ShareDestinationButton(
                label: String(localized: "share_copy_link"),
                color: Color(hex: "#8E8E93"),
                icon: "link"
            ) {
                dismissSheet()
            }

            ShareDestinationButton(
                label: String(localized: "share_more"),
                color: Color(hex: "#48484A"),
                icon: "ellipsis"
            ) {
                dismissSheet()
            }
        }
    }
}

private struct ShareDestinationButton: View {
    let label: String
    let color: Color
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color)
                        .frame(width: 54, height: 54)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.c2bDim)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LineupShareSheet(
        profile: .default,
        shows: [],
        isPremium: true
    )
    .preferredColorScheme(.dark)
}
