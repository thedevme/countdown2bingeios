import SwiftUI

// MARK: - Poster Component
struct PosterView: View {
    let title: String
    let season: String
    let platform: String
    let imageName: String?
    let tintColor: Color
    let width: CGFloat
    let radius: CGFloat
    let showBadge: Bool
    let showHint: Bool

    init(
        title: String,
        season: String,
        platform: String,
        imageName: String? = nil,
        tintColor: Color = .c2bTeal,
        width: CGFloat = 150,
        radius: CGFloat = 16,
        showBadge: Bool = true,
        showHint: Bool = true
    ) {
        self.title = title
        self.season = season
        self.platform = platform
        self.imageName = imageName
        self.tintColor = tintColor
        self.width = width
        self.radius = radius
        self.showBadge = showBadge
        self.showHint = showHint
    }

    var body: some View {
        ZStack {
            // Background gradient when no image
            LinearGradient(
                colors: [
                    tintColor.opacity(0.6),
                    Color(hex: "#0a0a0b")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Diagonal stripes pattern
            if imageName == nil {
                GeometryReader { geo in
                    Path { path in
                        let spacing: CGFloat = 11
                        let diagonal = sqrt(pow(geo.size.width, 2) + pow(geo.size.height, 2))

                        for i in stride(from: -diagonal, to: diagonal, by: spacing) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i + geo.size.height, y: geo.size.height))
                        }
                    }
                    .stroke(Color.white.opacity(0.04), lineWidth: 1.5)
                }
            }

            // Poster image if available
            if let imageName = imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }

            // Season watermark
            if imageName == nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(season)
                            .displayStyle(size: width * 0.5, color: Color.white.opacity(0.12))
                            .offset(y: width * 0.08)
                    }
                }
            }

            // Title overlay
            if imageName == nil {
                VStack {
                    HStack {
                        Text(title)
                            .displayStyle(size: max(13, width * 0.135), color: .white)
                            .multilineTextAlignment(.leading)
                            .padding(.leading, width * 0.07)
                            .padding(.top, width * 0.09)
                            .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Platform badge
            if showBadge {
                VStack {
                    HStack {
                        Spacer()
                        Text(platform)
                            .monoStyle(size: max(7, width * 0.052), color: Color(hex: "#e7e7e7"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.74))
                            .c2bBlur()
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .padding(7)
                    }
                    Spacer()
                }
            }

            // Poster hint
            if showHint && imageName == nil && width >= 90 {
                VStack {
                    Spacer()
                    Text("poster_placeholder")
                        .monoStyle(size: max(7, width * 0.045), color: Color.white.opacity(0.28))
                        .tracking(4)
                        .padding(.bottom, 7)
                }
            }
        }
        .frame(width: width, height: width / C2BLayout.posterAspectRatio)
        .cornerRadius(radius)
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .posterShadow()
    }
}

// MARK: - Chip Component
struct ChipView: View {
    let text: String
    let isActive: Bool

    init(_ text: String, isActive: Bool = false) {
        self.text = text
        self.isActive = isActive
    }

    var body: some View {
        Text(text)
            .uiStyle(size: 12, weight: .medium, color: isActive ? Color(hex: "#04201c") : .c2bDim)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(isActive ? Color.c2bTeal : Color.white.opacity(0.06))
            .cornerRadius(C2BLayout.chipRadius)
            .overlay(
                RoundedRectangle(cornerRadius: C2BLayout.chipRadius)
                    .stroke(isActive ? Color.clear : Color.white.opacity(0.09), lineWidth: 1)
            )
    }
}

// MARK: - Follow Button
struct FollowButton: View {
    let isFollowing: Bool
    let fullWidth: Bool

    init(isFollowing: Bool, fullWidth: Bool = false) {
        self.isFollowing = isFollowing
        self.fullWidth = fullWidth
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 13))

            Text(isFollowing ? "Following" : "Follow")
                .displayStyle(size: 16, color: isFollowing ? .c2bDim : Color(hex: "#04201c"))
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(isFollowing ? Color.white.opacity(0.07) : Color.c2bTeal)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFollowing ? Color.white.opacity(0.12) : Color.c2bTeal, lineWidth: 1)
        )
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let actionText: String?
    let onAction: (() -> Void)?

    init(title: String, actionText: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.actionText = actionText
        self.onAction = onAction
    }

    var body: some View {
        HStack(alignment: .bottom) {
            Text(title)
                .displayStyle(size: 21, color: .c2bText)

            Spacer()

            if let actionText = actionText, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionText)
                        .displayStyle(size: 14, color: .c2bTeal)
                }
            }
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Lifecycle Meter
struct LifecycleMeterView: View {
    let phase: String // "anticipated", "premiering", "airing", "ready"
    let progress: CGFloat?
    let size: String // "sm" or "lg"
    let showLabels: Bool

    init(phase: String, progress: CGFloat? = nil, size: String = "sm", showLabels: Bool = false) {
        self.phase = phase
        self.progress = progress
        self.size = size
        self.showLabels = showLabels
    }

    private var nodeIndex: Int {
        switch phase {
        case "anticipated": return 0
        case "premiering": return 1
        case "airing": return 2
        case "ready": return 3
        default: return 0
        }
    }

    private var progressFraction: CGFloat {
        progress ?? CGFloat(nodeIndex) / 3.0
    }

    private var dotSize: CGFloat {
        size == "lg" ? 13 : 10
    }

    private var lineHeight: CGFloat {
        size == "lg" ? 4 : 3
    }

    var body: some View {
        VStack(spacing: 7) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let offset = dotSize / 2

                ZStack(alignment: .leading) {
                    // Base line
                    RoundedRectangle(cornerRadius: lineHeight)
                        .fill(Color.white.opacity(0.10))
                        .frame(height: lineHeight)
                        .padding(.horizontal, offset)

                    // Progress fill
                    RoundedRectangle(cornerRadius: lineHeight)
                        .fill(C2BGradients.tealGradient)
                        .frame(width: (width - dotSize) * progressFraction, height: lineHeight)
                        .padding(.leading, offset)
                        .tealGlow()

                    // Nodes
                    HStack(spacing: 0) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index <= nodeIndex ? (index == nodeIndex ? Color.c2bTealBright : Color.c2bTeal) : Color(hex: "#1a1a1c"))
                                .frame(width: dotSize, height: dotSize)
                                .overlay(
                                    Circle()
                                        .stroke(index <= nodeIndex ? Color.clear : Color.white.opacity(0.18), lineWidth: 1.5)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(index == nodeIndex ? Color.c2bTeal.opacity(0.18) : Color.clear, lineWidth: 8)
                                )
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: dotSize)

            if showLabels {
                HStack {
                    ForEach(["Soon", "Premiere", "Airing", "Ready"], id: \.self) { label in
                        Text(label)
                            .monoStyle(
                                size: 8.5,
                                color: label == ["Soon", "Premiere", "Airing", "Ready"][nodeIndex] ? .c2bTealBright : .c2bMuted
                            )
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Phase Tag
struct PhaseTagView: View {
    let phase: String

    private var isReady: Bool { phase == "ready" }
    private var isAnticipated: Bool { phase == "anticipated" }

    private var label: String {
        switch phase {
        case "anticipated": return String(localized: "phase_anticipated")
        case "premiering": return String(localized: "phase_premiering_soon")
        case "airing": return String(localized: "phase_now_airing")
        case "ready": return String(localized: "phase_binge_ready")
        default: return String(localized: "phase_unknown")
        }
    }

    private var textColor: Color {
        if isAnticipated { return .c2bMuted }
        return isReady ? Color(hex: "#04201c") : .c2bTealBright
    }

    private var backgroundColor: Color {
        if isReady { return .c2bTeal }
        if isAnticipated { return Color.white.opacity(0.05) }
        return Color.c2bTeal.opacity(0.12)
    }

    private var borderColor: Color {
        if isReady { return .clear }
        if isAnticipated { return Color.white.opacity(0.08) }
        return .c2bTealLine
    }

    private var dotColor: Color {
        if isReady { return Color(hex: "#04201c") }
        if isAnticipated { return .c2bMuted }
        return .c2bTeal
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)

            Text(label)
                .monoStyle(size: 8.5, color: textColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(C2BLayout.chipRadius)
        .overlay(
            RoundedRectangle(cornerRadius: C2BLayout.chipRadius)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Countdown Display
struct CountdownView: View {
    let readyInDays: Int?
    let phase: String
    let episodes: Int
    let episodesAired: Int
    let countdownStyle: String // "days", "episodes", "progress"
    let big: Bool
    let readyAgo: String?

    init(
        readyInDays: Int?,
        phase: String,
        episodes: Int,
        episodesAired: Int,
        countdownStyle: String = "days",
        big: Bool = false,
        readyAgo: String? = nil
    ) {
        self.readyInDays = readyInDays
        self.phase = phase
        self.episodes = episodes
        self.episodesAired = episodesAired
        self.countdownStyle = countdownStyle
        self.big = big
        self.readyAgo = readyAgo
    }

    private var numberSize: CGFloat { big ? 64 : 34 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Eyebrow
            Text(eyebrowText)
                .monoStyle(size: 9.5, color: eyebrowColor)

            // Main content
            mainContent

            // Subtext
            Text(subtextContent)
                .monoStyle(size: 9.5, color: .c2bDim)
                .padding(.top, 1)
        }
    }

    private var eyebrowText: String {
        if phase == "ready" { return String(localized: "phase_ready_to_binge") }
        if phase == "anticipated" { return String(localized: "phase_binge_ready") }
        if phase == "premiering" { return String(localized: "phase_binge_ready_in") }
        return String(localized: "phase_binge_ready_in")
    }

    private var eyebrowColor: Color {
        if phase == "ready" { return .c2bTealBright }
        if phase == "anticipated" { return .c2bMuted }
        return .c2bTeal
    }

    @ViewBuilder
    private var mainContent: some View {
        if countdownStyle == "episodes" && phase != "anticipated" {
            HStack(alignment: .bottom, spacing: 6) {
                Text("\(episodesAired)")
                    .displayStyle(size: numberSize, color: .white)
                Text("/ \(episodes)")
                    .displayStyle(size: numberSize * 0.5, color: .c2bMuted)
            }
        } else if countdownStyle == "progress" && phase != "anticipated" {
            let pct = phase == "ready" ? 100 : Int((Double(episodesAired) / Double(episodes)) * 100)
            HStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 0) {
                    Text("\(pct)")
                        .displayStyle(size: numberSize * 0.82, color: pct == 100 ? .c2bTealBright : .white)
                    Text("%")
                        .displayStyle(size: numberSize * 0.4, color: pct == 100 ? .c2bTealBright : .white)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 7)

                        RoundedRectangle(cornerRadius: 7)
                            .fill(C2BGradients.tealGradient)
                            .frame(width: geo.size.width * CGFloat(pct) / 100, height: 7)
                    }
                }
                .frame(height: 7)
            }
        } else if phase == "ready" {
            Text("status_now")
                .displayStyle(size: numberSize, color: .c2bTealBright)
        } else if phase == "anticipated" {
            Text("timeline_tba")
                .displayStyle(size: numberSize * 0.78, color: .c2bMuted)
        } else if let days = readyInDays {
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(days)")
                    .displayStyle(size: numberSize, color: .white)
                Text(days == 1 ? String(localized: "time_day") : String(localized: "time_days"))
                    .monoStyle(size: 11, color: .c2bDim)
            }
        }
    }

    private var subtextContent: String {
        if countdownStyle == "episodes" && phase != "anticipated" {
            let remaining = episodes - episodesAired
            return phase == "ready" ? String(localized: "subtext_all_episodes_out") : String(localized: "subtext_left_to_release \(remaining)")
        } else if countdownStyle == "progress" && phase != "anticipated" {
            let pct = phase == "ready" ? 100 : Int((Double(episodesAired) / Double(episodes)) * 100)
            return pct == 100 ? String(localized: "subtext_season_complete") : String(localized: "subtext_of_season_released")
        } else if phase == "ready" {
            return String(localized: "subtext_episodes_ready \(episodes) \(readyAgo ?? String(localized: "subtext_all_out"))")
        } else if phase == "anticipated" {
            return String(localized: "subtext_no_date_yet")
        } else {
            return readyInDays != nil ? String(localized: "status_until_binge_ready") : ""
        }
    }
}
