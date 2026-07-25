import SwiftUI
import SwiftData

// MARK: - Timeline Screen
struct TimelineScreen: View {
    let layout: String // "expanded" or "compact"
    let numberStyle: String // "rotated", "stacked", "chip"
    var refreshTrigger: UUID = UUID()
    var onInfoTap: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TimelineViewModel = TimelineViewModel()
    @State private var heroCardIndex: Int = 0
    @State private var showNotificationSettings = false
    @State private var navigationPath = NavigationPath()

    /// Countdown value for the currently displayed hero card
    private var currentHeroCountdown: Int? {
        guard !viewModel.heroShowTuples.isEmpty,
              heroCardIndex < viewModel.heroShowTuples.count else {
            return nil
        }
        return viewModel.heroShowTuples[heroCardIndex].daysUntilFinale
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                TimelineHeader(
                    onBellTap: { showNotificationSettings = true },
                    onInfoTap: onInfoTap
                )

                    // Stats Bar
                    StatsBar(
                        tracked: viewModel.trackedCount,
                        upcoming: viewModel.upcomingCount
                    )
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    // Hero Card Stack
                    if viewModel.heroShowTuples.isEmpty {
                        HeroShowCard(show: nil, daysUntilFinale: nil)
                            .padding(.top, 14)
                    } else {
                        HeroCardStack(
                            shows: viewModel.heroShowTuples,
                            currentIndex: $heroCardIndex,
                            onShowTap: { show in
                                navigationPath.append(show)
                            },
                            cardSize: CGSize(width: 280, height: 420)
                        )
                        .padding(.top, 14)
                    }

                    // Day Ticker - syncs with current hero card
                    DayTicker(
                        value: currentHeroCountdown,
                        displayMode: .days
                    )
                    .padding(.vertical, 10)

                    // View Timeline Button
                    Button(action: { navigationPath.append("fullTimeline") }) {
                        Text("button_view_timeline")
                            .monoStyle(size: 11, color: .c2bText)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 13)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(13)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 26)

                    // Premiering Soon Section
                    premieringSoonSection

                    // Anticipated Section
                    anticipatedSection
                        .padding(.top, 20)

                    // Footer
                    CycleFooter()
                        .padding(.top, 34)

                    Spacer()
                        .frame(height: 150)
                }
            }
            .onAppear {
                viewModel.configure(with: modelContext)
                Task {
                    await viewModel.loadFollowedShows()
                }
            }
            .onChange(of: refreshTrigger) { _, _ in
                Task {
                    await viewModel.loadFollowedShows()
                }
            }
            .navigationDestination(for: ShowData.self) { show in
                FollowedShowDetail(
                    show: show,
                    onDismiss: { navigationPath.removeLast() },
                    onUnfollow: {
                        Task { await viewModel.unfollowShow(show) }
                    }
                )
                .navigationBarHidden(true)
            }
            .navigationDestination(for: String.self) { route in
                if route == "fullTimeline" {
                    FullTimelineView(
                        viewModel: viewModel,
                        navigationPath: $navigationPath
                    )
                    .navigationBarHidden(true)
                }
            }
        }
        .overlay {
            if showNotificationSettings {
                NotificationSettingsModal(onDismiss: { showNotificationSettings = false })
            }
        }
    }

    // MARK: - Section Views

    @ViewBuilder
    private var premieringSoonSection: some View {
        TimelineSection(
            title: String(localized: "header_premiering_soon"),
            tone: .c2bTeal,
            count: viewModel.premieringSoonShows.count
        ) { isExpanded in
            VStack(spacing: isExpanded ? 16 : 10) {
                if viewModel.premieringSoonShows.isEmpty {
                    if isExpanded {
                        TimelineEmptySection()
                    } else {
                        MiniEmptySection(dim: false)
                    }
                } else {
                    ForEach(viewModel.premieringSoonShows, id: \.id) { show in
                        Button(action: { navigationPath.append(show) }) {
                            if isExpanded {
                                PremieringCard(showData: show)
                            } else {
                                MiniPremieringCard(showData: show)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, C2BLayout.horizontalPadding)
        }
    }

    @ViewBuilder
    private var anticipatedSection: some View {
        TimelineSection(
            title: String(localized: "header_anticipated"),
            tone: .c2bMuted,
            count: viewModel.anticipatedShows.count
        ) { isExpanded in
            VStack(spacing: isExpanded ? 16 : 10) {
                if viewModel.anticipatedShows.isEmpty {
                    if isExpanded {
                        TimelineEmptySection()
                    } else {
                        MiniEmptySection(dim: true)
                    }
                } else {
                    ForEach(viewModel.anticipatedShows, id: \.id) { show in
                        Button(action: { navigationPath.append(show) }) {
                            if isExpanded {
                                AnticipatedCard(showData: show)
                            } else {
                                MiniAnticipatedCard(showData: show)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, C2BLayout.horizontalPadding)
        }
    }
}

// MARK: - Timeline Empty Section
struct TimelineEmptySection: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                style: StrokeStyle(lineWidth: 1.5, dash: [5])
            )
            .foregroundColor(Color.white.opacity(0.08))
            .frame(height: 60)
            .overlay(
                Text("empty_slot")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                    .foregroundColor(Color(hex: "#52525b"))
                    .textCase(.uppercase)
                    .tracking(1.6)
            )
    }
}

// MARK: - Timeline Header
struct TimelineHeader: View {
    let onBellTap: () -> Void
    var onInfoTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Notifications Button (left)
            Button(action: onBellTap) {
                Image(systemName: "bell")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(Color(hex: "#cfcfcf"))
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(21)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }

            Spacer()

            // Info Button (right - launches walkthrough)
            if let onInfoTap {
                Button(action: onInfoTap) {
                    Image(systemName: "info")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(Color(hex: "#cfcfcf"))
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(21)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, C2BLayout.horizontalPadding)
        .padding(.top, 50)
        .padding(.bottom, 6)
    }
}

// MARK: - Stats Bar
struct StatsBar: View {
    let tracked: Int
    let upcoming: Int

    var body: some View {
        HStack(spacing: 0) {
            StatCell(number: String(format: "%02d", tracked), label: String(localized: "stats_tracked"))

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)

            StatCell(number: String(format: "%02d", upcoming), label: String(localized: "stats_upcoming"))
        }
        .frame(height: 74)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct StatCell: View {
    let number: String
    let label: String

    var body: some View {
        ZStack {
            // Background watermark number
            Text(number)
                .displayStyle(size: 76, color: Color.c2bTeal.opacity(0.16))
                .offset(y: 0)

            // Foreground content
            VStack(spacing: 5) {
                Text(number)
                    .displayStyle(size: 26, color: .c2bTealBright)

                Text(label)
                    .monoStyle(size: 8.5, color: .c2bDim)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Day Ticker
struct DayTicker: View {
    let value: Int?
    let displayMode: CountdownDisplayMode

    private var centerDay: Int {
        value ?? 0
    }

    private var unitLabel: String {
        displayMode.unit
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ForEach(-2...2, id: \.self) { offset in
                    let day = centerDay + offset
                    let isCenter = offset == 0
                    let isPastDay = day < 0

                    VStack(spacing: isCenter ? 3 : 3) {
                        if value == nil && isCenter {
                            Text("timeline_tbd")
                                .displayStyle(
                                    size: 26,
                                    color: .white
                                )
                        } else if isPastDay {
                            // Show dash for past days (negative values)
                            Text("–")
                                .displayStyle(
                                    size: 26,
                                    color: .white
                                )
                        } else {
                            Text("\(day)")
                                .displayStyle(
                                    size: isCenter ? 34 : 26,
                                    color: .white
                                )
                        }

                        Text(unitLabel)
                            .monoStyle(
                                size: isCenter ? 8.5 : 7,
                                color: isCenter ? .c2bTealBright : .c2bMuted
                            )
                    }
                    .padding(.horizontal, isCenter ? 16 : 0)
                    .padding(.vertical, isCenter ? 8 : 0)
                    .background(
                        isCenter ?
                        Color.c2bTeal.opacity(0.05) :
                        Color.clear
                    )
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isCenter ? Color.c2bTealLine : Color.clear, lineWidth: 1)
                    )
                    .opacity(isCenter ? 1.0 : (abs(offset) == 1 ? 0.4 : 0.2))
                }
            }
            .padding(.vertical, 6)
            .animation(.easeOut(duration: 0.3), value: centerDay)

            Text(String(localized: "today_date \(formattedDate)"))
                .monoStyle(size: 9.5, color: .c2bMuted)
                .padding(.top, 12)

            // Gradient line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.c2bTeal, Color.c2bTeal.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: 40)
                .padding(.top, 10)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Timeline Section
struct TimelineSection<Content: View>: View {
    let title: String
    let tone: Color
    let count: Int
    @ViewBuilder let content: (_ isExpanded: Bool) -> Content
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Button(action: { withAnimation { isExpanded.toggle() }}) {
                HStack(spacing: 9) {
                    Circle()
                        .fill(tone)
                        .frame(width: 8, height: 8)

                    Text(title)
                        .displayStyle(size: 16, color: .c2bText)

                    Text("\(count)")
                        .monoStyle(
                            size: 9,
                            color: tone == .c2bMuted ? .c2bDim : .c2bTealBright
                        )
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            tone == .c2bMuted ?
                            Color.white.opacity(0.06) :
                            Color.c2bTeal.opacity(0.12)
                        )
                        .cornerRadius(C2BLayout.chipRadius)

                    Spacer()

                    Text(isExpanded ? String(localized: "button_hide") : String(localized: "button_show"))
                        .monoStyle(size: 8.5, color: .c2bMuted)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.c2bMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, C2BLayout.horizontalPadding)
                .padding(.bottom, 14)
            }

            // Content - always shown, just in different modes
            content(isExpanded)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Soon Row (Premiering Soon)
struct SoonRow: View {
    let layout: String
    let numberStyle: String
    let days: Int
    let isEmpty: Bool

    var body: some View {
        if layout == "compact" {
            CompactSoonRow(numberStyle: numberStyle, days: days, isEmpty: isEmpty)
        } else {
            ExpandedSoonRow(numberStyle: numberStyle, days: days, isEmpty: isEmpty)
        }
    }
}

struct CompactSoonRow: View {
    let numberStyle: String
    let days: Int
    let isEmpty: Bool

    var body: some View {
        HStack(spacing: 4) {
            GiantNumber(
                number: days,
                unit: String(localized: "time_days"),
                sub: String(localized: "timeline_to_premiere"),
                dim: false,
                empty: isEmpty,
                dense: false,
                style: numberStyle
            )

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#101012"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(
                        Rectangle()
                            .fill(Color.c2bTealLine)
                            .frame(width: 2)
                            .cornerRadius(2, corners: [.topLeft, .bottomLeft]),
                        alignment: .leading
                    )

                if isEmpty {
                    Text("empty_slot")
                        .monoStyle(size: 11, color: .c2bMuted)
                } else {
                    // Poster overlay here
                    Text("poster_placeholder")
                        .monoStyle(size: 11, color: .c2bDim)
                }
            }
        }
        .frame(height: 132)
        .padding(.bottom, 16)
    }
}

struct ExpandedSoonRow: View {
    let numberStyle: String
    let days: Int
    let isEmpty: Bool

    var body: some View {
        HStack(spacing: 8) {
            GiantNumber(
                number: days,
                unit: String(localized: "time_days"),
                sub: String(localized: "timeline_to_premiere"),
                dim: false,
                empty: isEmpty,
                dense: false,
                style: numberStyle
            )

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#101012"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .cardShadow()

                if isEmpty {
                    Text("empty_slot")
                        .monoStyle(size: 11, color: .c2bMuted)
                } else {
                    // Poster content here
                    Text("poster_placeholder")
                        .monoStyle(size: 11, color: .c2bDim)
                }
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .padding(.bottom, 22)
    }
}

// MARK: - Anticipated Row
struct AnticipatedRow: View {
    let layout: String
    let numberStyle: String
    let year: Int
    let isEmpty: Bool

    var body: some View {
        if layout == "compact" {
            CompactAnticipatedRow(numberStyle: numberStyle, year: year, isEmpty: isEmpty)
        } else {
            ExpandedAnticipatedRow(numberStyle: numberStyle, year: year, isEmpty: isEmpty)
        }
    }
}

struct CompactAnticipatedRow: View {
    let numberStyle: String
    let year: Int
    let isEmpty: Bool

    var body: some View {
        HStack(spacing: 4) {
            GiantNumber(
                number: year,
                unit: String(localized: "timeline_expected"),
                sub: String(localized: "timeline_release"),
                dim: true,
                empty: isEmpty,
                dense: true,
                style: numberStyle
            )

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#0c0c0e"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                            .foregroundColor(Color.white.opacity(0.12))
                    )

                if isEmpty {
                    Text("empty_slot")
                        .monoStyle(size: 11, color: Color.white.opacity(0.2))
                } else {
                    Text("poster_placeholder")
                        .monoStyle(size: 11, color: .c2bDim)
                }
            }
        }
        .frame(height: 120)
        .padding(.bottom, 16)
    }
}

struct ExpandedAnticipatedRow: View {
    let numberStyle: String
    let year: Int
    let isEmpty: Bool

    var body: some View {
        HStack(spacing: 8) {
            GiantNumber(
                number: year,
                unit: String(localized: "timeline_expected"),
                sub: String(localized: "timeline_release"),
                dim: true,
                empty: isEmpty,
                dense: false,
                style: numberStyle
            )

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#0c0c0e"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                            .foregroundColor(Color.white.opacity(0.12))
                    )

                if isEmpty {
                    Text("empty_slot")
                        .monoStyle(size: 11, color: Color.white.opacity(0.2))
                } else {
                    Text("poster_placeholder")
                        .monoStyle(size: 11, color: .c2bDim)
                }
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .padding(.bottom, 22)
    }
}

// MARK: - Giant Number Component
struct GiantNumber: View {
    let number: Int
    let unit: String
    let sub: String
    let dim: Bool
    let empty: Bool
    let dense: Bool
    let style: String // "rotated", "stacked", "chip"

    var body: some View {
        switch style {
        case "stacked":
            StackedNumber(number: number, unit: unit, sub: sub, dim: dim, empty: empty)
        case "chip":
            ChipNumber(number: number, unit: unit, sub: sub, dim: dim, empty: empty)
        default:
            RotatedNumber(number: number, unit: unit, sub: sub, dim: dim, empty: empty, dense: dense)
        }
    }
}

struct RotatedNumber: View {
    let number: Int
    let unit: String
    let sub: String
    let dim: Bool
    let empty: Bool
    let dense: Bool

    var body: some View {
        ZStack {
            // Rotated number
            Text(empty ? "XX" : "\(number)")
                .displayStyle(
                    size: String(number).count >= 4 && dense ? 30 : (String(number).count >= 4 ? 40 : 82),
                    color: dim ? Color.white.opacity(0.42) : Color.white.opacity(0.88)
                )
                .rotationEffect(.degrees(-90))

            // Upright label
            VStack(alignment: .leading, spacing: 3) {
                Spacer()

                Rectangle()
                    .fill(dim ? Color.white.opacity(0.82) : Color.c2bTealBright)
                    .frame(width: 66, height: 2)
                    .cornerRadius(2)
                    .opacity(0.8)

                Text(unit)
                    .displayStyle(
                        size: unit.count > 4 ? 13 : 25,
                        color: dim ? Color.white.opacity(0.82) : .c2bTealBright
                    )
                    .lineLimit(1)

                if !sub.isEmpty {
                    Text(sub)
                        .monoStyle(size: 9, color: dim ? Color.white.opacity(0.5) : .c2bMuted)
                }
            }
            .frame(width: 66, alignment: .leading)
            .padding(.leading, 5)
            .padding(.bottom, 10)
            .offset(x: -28)
        }
        .frame(width: 56)
    }
}

struct StackedNumber: View {
    let number: Int
    let unit: String
    let sub: String
    let dim: Bool
    let empty: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(empty ? "XX" : "\(number)")
                .displayStyle(size: empty ? 40 : 48, color: dim ? .c2bDim : .white)

            Text(unit)
                .monoStyle(size: 9, color: dim ? Color.white.opacity(0.82) : .c2bTealBright)

            if !sub.isEmpty {
                Text(sub)
                    .monoStyle(size: 7, color: .c2bMuted)
            }
        }
        .frame(width: 62)
    }
}

struct ChipNumber: View {
    let number: Int
    let unit: String
    let sub: String
    let dim: Bool
    let empty: Bool

    var body: some View {
        VStack(spacing: 5) {
            Text(empty ? "XX" : "\(number)")
                .displayStyle(size: empty ? 30 : 36, color: dim ? .c2bDim : .white)

            Text(unit)
                .monoStyle(size: 7.5, color: dim ? Color.white.opacity(0.82) : .c2bTealBright)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 11)
        .frame(minWidth: 50)
        .background(dim ? Color.white.opacity(0.02) : Color.c2bTeal.opacity(0.06))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(dim ? Color.white.opacity(0.14) : Color.c2bTealLine, lineWidth: 1.5)
        )
        .frame(width: 62)
    }
}

// MARK: - Cycle Footer
struct CycleFooter: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(.c2bMuted)
                .opacity(0.7)

            Text("footer_cycle_message")
                .monoStyle(size: 9, color: .c2bMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(7)
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Helper Extension for Rounded Corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Notification Settings Modal
struct NotificationSettingsModal: View {
    let onDismiss: () -> Void

    @AppStorage("notif_push") private var pushEnabled = true
    @AppStorage("notif_premiere") private var premiereEnabled = true
    @AppStorage("notif_bingeReady") private var bingeReadyEnabled = true
    @AppStorage("notif_weekly") private var weeklyEnabled = false
    @AppStorage("notif_leadDays") private var leadDays = 3
    @AppStorage("notif_email") private var emailEnabled = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Sheet
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Title
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.c2bTealBright)

                    Text("header_notification_settings")
                        .font(.custom(.oswald.bold, size: 22))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Settings
                VStack(spacing: 0) {
                    NotificationSettingsRow(
                        title: String(localized: "notif_push_title"),
                        subtitle: String(localized: "notif_push_subtitle"),
                        isOn: $pushEnabled
                    )
                    NotificationSettingsRow(
                        title: String(localized: "notif_premiere_title"),
                        subtitle: String(localized: "notif_premiere_subtitle"),
                        isOn: $premiereEnabled
                    )
                    NotificationSettingsRow(
                        title: String(localized: "notif_binge_ready_title"),
                        subtitle: String(localized: "notif_binge_ready_subtitle"),
                        isOn: $bingeReadyEnabled
                    )
                    NotificationSettingsRow(
                        title: String(localized: "notif_weekly_title"),
                        subtitle: String(localized: "notif_weekly_subtitle"),
                        isOn: $weeklyEnabled
                    )

                    // Lead time picker
                    LeadTimePickerRow(leadDays: $leadDays)

                    NotificationSettingsRow(
                        title: String(localized: "notif_email_title"),
                        subtitle: String(localized: "notif_email_subtitle"),
                        isOn: $emailEnabled,
                        isLast: true
                    )
                }
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // Done Button
                Button(action: onDismiss) {
                    Text("button_done")
                        .font(.custom(.oswald.bold, size: 16))
                        .tracking(0.48)
                        .foregroundColor(Color(hex: "#04201c"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.c2bTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 34)
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
        }
    }
}

// MARK: - Notification Settings Row
private struct NotificationSettingsRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.c2bMuted)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.c2bTeal)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .background(
            VStack {
                Spacer()
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                }
            }
        )
    }
}

// MARK: - Lead Time Picker Row
private struct LeadTimePickerRow: View {
    @Binding var leadDays: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("notif_remind_early_title")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(.white)

                Text("notif_remind_early_subtitle")
                    .font(.system(size: 11))
                    .foregroundColor(.c2bMuted)
            }

            Spacer()

            HStack(spacing: 6) {
                LeadDayButton(days: 1, selectedDays: $leadDays)
                LeadDayButton(days: 3, selectedDays: $leadDays)
                LeadDayButton(days: 7, selectedDays: $leadDays)
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .background(
            VStack {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                Spacer()
            }
        )
    }
}

// MARK: - Lead Day Button
private struct LeadDayButton: View {
    let days: Int
    @Binding var selectedDays: Int

    private var isSelected: Bool { selectedDays == days }

    var body: some View {
        Button(action: { selectedDays = days }) {
            Text(String(localized: "time_days_short \(days)"))
                .font(.custom(.jetbrains.bold, size: 10))
                .tracking(0.6)
                .foregroundColor(isSelected ? Color(hex: "#04201c") : .c2bDim)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(buttonBackground)
                .overlay(buttonOverlay)
        }
        .buttonStyle(.plain)
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(isSelected ? Color.c2bTeal : Color.white.opacity(0.06))
    }

    private var buttonOverlay: some View {
        RoundedRectangle(cornerRadius: 9)
            .stroke(isSelected ? Color.c2bTeal : Color.white.opacity(0.1), lineWidth: 1)
    }
}
