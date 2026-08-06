//
//  ShareSheet.swift
//  Countdown2Binge
//
//  Custom share sheet with binge card preview.
//

import SwiftUI

struct ShareSheet: View {
    let show: ShowData
    let onClose: () -> Void

    @State private var variant: ShareVariant = .countingDown
    @State private var countdownText = "I'm waiting to binge this one start to finish. 🍿"
    @State private var bingedText = ""
    @State private var isPresented = false

    enum ShareVariant {
        case countingDown
        case justBinged
    }

    private var defaultBingedText: String {
        String(localized: "share_default_binged \(episodeCount)")
    }

    private var seasonNumber: String {
        "\(show.currentSeason?.seasonNumber ?? show.numberOfSeasons)"
    }

    private var daysUntilBinge: Int? {
        show.daysUntilFinale ?? show.daysUntilPremiere
    }

    private var statBig: String {
        if let days = daysUntilBinge {
            return "\(days)"
        }
        switch show.timelineCategory {
        case .bingeReady: return "NOW"
        case .anticipated: return "TBD"
        default: return "—"
        }
    }

    private var statLabel: String {
        switch show.timelineCategory {
        case .airingNow: return String(localized: "status_until_binge_ready")
        case .premieringSoon: return String(localized: "share_until_premiere")
        case .anticipated: return String(localized: "share_release_pending")
        case .bingeReady: return String(localized: "status_ready_to_binge")
        }
    }

    private var episodeCount: Int {
        show.currentSeason?.episodeCount ?? 0
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
                    // Sheet content
                    VStack(spacing: 0) {
                        // Drag handle
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 4)
                            .padding(.top, 8)
                            .padding(.bottom, 12)

                        // Variant toggle
                        HStack(spacing: 4) {
                            VariantButton(
                                title: String(localized: "share_counting_down"),
                                isSelected: variant == .countingDown,
                                action: { variant = .countingDown }
                            )
                            VariantButton(
                                title: String(localized: "share_just_binged"),
                                isSelected: variant == .justBinged,
                                action: { variant = .justBinged }
                            )
                        }
                        .padding(3)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                        // Binge Card
                        BingeCard(
                            show: show,
                            variant: variant,
                            seasonNumber: seasonNumber,
                            statBig: statBig,
                            statLabel: statLabel,
                            customText: variant == .countingDown ? countdownText : (bingedText.isEmpty ? defaultBingedText : bingedText)
                        )
                        .padding(.horizontal, 20)

                        // Editable message
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(.c2bMuted)

                            if variant == .countingDown {
                                TextField("share_enter_message", text: $countdownText)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .tint(.c2bTeal)
                            } else {
                                TextField(defaultBingedText, text: $bingedText)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .tint(.c2bTeal)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Share destinations
                        HStack(spacing: 8) {
                            ShareDestination(label: String(localized: "share_messages"), color: Color(hex: "#34C759"), icon: "message.fill")
                            ShareDestination(label: String(localized: "share_instagram"), color: Color(hex: "#E1306C"), icon: "camera.fill")
                            ShareDestination(label: String(localized: "share_copy_link"), color: Color(hex: "#8E8E93"), icon: "link")
                            ShareDestination(label: String(localized: "share_more"), color: Color(hex: "#48484A"), icon: "ellipsis")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Cancel button
                        Button(action: { dismissSheet() }) {
                            Text("button_cancel")
                                .font(.custom(.oswald.regular, size: 13))
                                .tracking(0.78)
                                .foregroundColor(.c2bDim)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
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
}

// MARK: - Variant Button

private struct VariantButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.custom(.jetbrains.bold, size: 9.5))
                .tracking(0.76)
                .foregroundColor(isSelected ? Color(hex: "#04201c") : .c2bDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.c2bTeal : Color.clear)
                .cornerRadius(8)
        }
    }
}

// MARK: - Binge Card

private struct BingeCard: View {
    let show: ShowData
    let variant: ShareSheet.ShareVariant
    let seasonNumber: String
    let statBig: String
    let statLabel: String
    let customText: String

    private var isFinished: Bool {
        variant == .justBinged
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image section
            ZStack(alignment: .bottom) {
                // Background image
                AsyncImage(url: show.backdropURL ?? show.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                            .saturation(isFinished ? 1.1 : 1.0)
                    default:
                        Rectangle()
                            .fill(Color.c2bSurface)
                            .frame(height: 180)
                    }
                }
                .frame(height: 180)

                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color(hex: "#0b0b0c"),
                        Color(hex: "#0b0b0c").opacity(0.15),
                        Color(hex: "#0b0b0c").opacity(0.4)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // App badge (top left)
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.c2bTealBright)
                                .frame(width: 5, height: 5)
                            Text("COUNTDOWN2BINGE")
                                .font(.custom(.jetbrains.bold, size: 8))
                                .tracking(1.12)
                                .foregroundColor(.c2bTealBright)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#080808").opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color.c2bTealLine, lineWidth: 1)
                        )
                        .cornerRadius(999)

                        Spacer()

                        // Binged badge (top right, only when finished)
                        if isFinished {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "#04201c"))
                                Text("share_binged")
                                    .font(.custom(.jetbrains.bold, size: 8))
                                    .tracking(0.96)
                                    .foregroundColor(Color(hex: "#04201c"))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.c2bTeal)
                            .cornerRadius(999)
                            .shadow(color: Color.c2bTeal.opacity(0.5), radius: 14, y: 4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    Spacer()
                }

                // Title area (bottom)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(show.name)
                        .font(.custom(.oswald.bold, size: 24))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.8), radius: 12, y: 2)

                    HStack(spacing: 0) {
                        Text("season_abbrev")
                            .font(.custom(.oswald.bold, size: 16))
                        Text(seasonNumber)
                            .font(.custom(.oswald.light, size: 16))
                    }
                    .foregroundColor(.white)
                    .fixedSize()

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(height: 180)

            // Bottom strip
            HStack(spacing: 10) {
                // Stat section
                VStack(spacing: 0) {
                    if isFinished {
                        Circle()
                            .fill(Color.c2bTeal.opacity(0.16))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.c2bTealLine, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.c2bTealBright)
                            )
                    } else {
                        Text(statBig)
                            .font(.custom(.oswald.bold, size: statBig == "NOW" || statBig == "TBD" ? 26 : 36))
                            .foregroundColor(.c2bTealBright)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        if statBig != "NOW" && statBig != "TBD" && statBig != "—" {
                            Text("time_days")
                                .font(.custom(.jetbrains.bold, size: 7))
                                .tracking(0.98)
                                .foregroundColor(.c2bMuted)
                                .padding(.top, 3)
                        }
                    }
                }
                .frame(minWidth: 50)

                // Text section
                VStack(alignment: .leading, spacing: 4) {
                    Text(isFinished ? String(localized: "share_season_complete") : statLabel.uppercased())
                        .font(.custom(.jetbrains.bold, size: 8))
                        .tracking(1.12)
                        .foregroundColor(.c2bTeal)

                    Text(customText)
                        .font(.system(size: 11))
                        .foregroundColor(.c2bDim)
                        .lineSpacing(1)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: "#0b0b0c"))
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 44, y: 16)
    }
}

// MARK: - Share Destination

private struct ShareDestination: View {
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.c2bDim)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
