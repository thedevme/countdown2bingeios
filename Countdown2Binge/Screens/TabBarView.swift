import SwiftUI

// MARK: - Tab Bar Component
struct C2BTabBar: View {
    @Binding var activeTab: String
    let onSearchTap: () -> Void
    var badgeManager: TabBadgeManager? = nil

    private let tabs = [
        TabItem(id: "timeline", label: String(localized: "tab_timeline"), icon: "list.bullet.rectangle"),
        TabItem(id: "discover", label: String(localized: "tab_discover"), icon: "safari"),
        TabItem(id: "binge", label: String(localized: "tab_binge_ready"), icon: "popcorn"),
        TabItem(id: "settings", label: String(localized: "tab_settings"), icon: "gearshape")
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(tabs) { tab in
                TabButton(
                    tab: tab,
                    isActive: activeTab == tab.id,
                    showBadge: badgeManager?.hasBadge(for: tab.id) ?? false,
                    onTap: {
                        activeTab = tab.id
                        // Clear badge when tab is tapped
                        badgeManager?.clearBadge(for: tab.id)
                    }
                )
            }
        }
        .padding(7)
        .background(Color(hex: "#161618").opacity(0.82))
        .c2bBlur()
        .cornerRadius(C2BLayout.chipRadius)
        .overlay(
            RoundedRectangle(cornerRadius: C2BLayout.chipRadius)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .tabBarShadow()
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }
}

// MARK: - Tab Item Model
struct TabItem: Identifiable {
    let id: String
    let label: String
    let icon: String
}

// MARK: - Tab Button
struct TabButton: View {
    let tab: TabItem
    let isActive: Bool
    var showBadge: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(isActive ? .c2bTealBright : .c2bMuted)

                    // Badge dot
                    if showBadge {
                        Circle()
                            .fill(Color.c2bTeal)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "#161618"), lineWidth: 1.5)
                            )
                            .offset(x: 4, y: -2)
                    }
                }

                Text(tab.label)
                    .monoStyle(size: 8.5, color: isActive ? .c2bText : .c2bMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isActive ? Color.white.opacity(0.10) : Color.clear)
            .cornerRadius(C2BLayout.chipRadius)
        }
    }
}

// MARK: - Custom Tab Icons (if needed for more accurate designs)
struct TimelineIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(color, lineWidth: 1.9)
                .frame(width: 13, height: 6)
                .offset(x: -4.5, y: -2)

            RoundedRectangle(cornerRadius: 3)
                .stroke(color, lineWidth: 1.9)
                .frame(width: 13, height: 6)
                .offset(x: 4.5, y: 3)

            Rectangle()
                .fill(color)
                .frame(width: 10, height: 1.9)
                .offset(x: -9.5, y: 0)

            Rectangle()
                .fill(color)
                .frame(width: 2, height: 1.9)
                .offset(x: -13, y: 0)
        }
        .frame(width: 22, height: 22)
    }
}

struct DiscoverIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 1.9)
                .frame(width: 5, height: 5)

            Circle()
                .stroke(color, lineWidth: 1.9)
                .frame(width: 12, height: 12)

            Circle()
                .stroke(color, lineWidth: 1.9)
                .frame(width: 19, height: 19)
        }
        .frame(width: 22, height: 22)
    }
}

struct BingeIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            // Popcorn box shape
            Path { path in
                path.move(to: CGPoint(x: 5, y: 9))
                path.addLine(to: CGPoint(x: 6.2, y: 20.2))
                path.addQuadCurve(
                    to: CGPoint(x: 7.2, y: 21),
                    control: CGPoint(x: 6.2, y: 20.8)
                )
                path.addLine(to: CGPoint(x: 14.8, y: 21))
                path.addQuadCurve(
                    to: CGPoint(x: 15.8, y: 20.2),
                    control: CGPoint(x: 15.8, y: 20.8)
                )
                path.addLine(to: CGPoint(x: 17, y: 9))
                path.closeSubpath()
            }
            .stroke(color, lineWidth: 1.9)

            // Top kernels
            Path { path in
                path.move(to: CGPoint(x: 5, y: 9))
                path.addLine(to: CGPoint(x: 7, y: 5))
                path.move(to: CGPoint(x: 11, y: 9))
                path.addLine(to: CGPoint(x: 12, y: 4))
                path.move(to: CGPoint(x: 17, y: 9))
                path.addLine(to: CGPoint(x: 15, y: 5))
            }
            .stroke(color, lineWidth: 1.9)
        }
        .frame(width: 22, height: 22)
    }
}

struct SettingsIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 1.9)
                .frame(width: 6.4, height: 6.4)

            ForEach(0..<4) { index in
                let angle = Double(index) * 90.0
                Rectangle()
                    .fill(color)
                    .frame(width: 1.9, height: 5.5)
                    .offset(y: -8.25)
                    .rotationEffect(.degrees(angle))

                Rectangle()
                    .fill(color)
                    .frame(width: 1.9, height: 5.5)
                    .offset(y: -8.25)
                    .rotationEffect(.degrees(angle + 45))
            }
        }
        .frame(width: 22, height: 22)
    }
}
