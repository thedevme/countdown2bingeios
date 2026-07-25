import SwiftUI

// MARK: - Free Limit Modal
struct FreeLimitModal: View {
    @Binding var isPresented: Bool
    @Binding var followedShows: [String]
    let onUpgrade: () -> Void

    @State private var markedForRemoval: Set<String> = []
    @State private var showOverlay: Bool = false
    @State private var showSheet: Bool = false

    private let freeLimit = 3

    private var overCount: Int {
        max(0, followedShows.count - freeLimit)
    }

    private var keepCount: Int {
        followedShows.count - markedForRemoval.count
    }

    private var stillOverCount: Int {
        max(0, keepCount - freeLimit)
    }

    private var canRemove: Bool {
        markedForRemoval.count > 0 && keepCount <= freeLimit && keepCount >= 1
    }

    private var atLimit: Bool {
        followedShows.count <= freeLimit
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black
                .opacity(showOverlay ? 0.7 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.35), value: showOverlay)

            // Bottom sheet
            VStack {
                Spacer()

                FreeLimitSheet(
                    followedShows: followedShows,
                    markedForRemoval: $markedForRemoval,
                    freeLimit: freeLimit,
                    overCount: overCount,
                    stillOverCount: stillOverCount,
                    canRemove: canRemove,
                    atLimit: atLimit,
                    onCommit: commitRemoval,
                    onContinue: continueFree,
                    onUpgrade: {
                        onUpgrade()
                        dismissModal()
                    }
                )
                .offset(y: showSheet ? 0 : 1000)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showSheet)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                showOverlay = true
                showSheet = true
            }
        }
    }

    private func commitRemoval() {
        followedShows.removeAll { markedForRemoval.contains($0) }
        markedForRemoval.removeAll()
    }

    private func continueFree() {
        dismissModal()
    }

    private func dismissModal() {
        showSheet = false
        showOverlay = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            isPresented = false
        }
    }
}

// MARK: - Free Limit Sheet
struct FreeLimitSheet: View {
    let followedShows: [String]
    @Binding var markedForRemoval: Set<String>
    let freeLimit: Int
    let overCount: Int
    let stillOverCount: Int
    let canRemove: Bool
    let atLimit: Bool
    let onCommit: () -> Void
    let onContinue: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 18)

            // Header badges
            HStack(spacing: 9) {
                Text("free_plan_badge")
                    .monoStyle(size: 9, color: Color(hex: "#04201c"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.c2bMuted)
                    .cornerRadius(999)

                Text(String(localized: "free_shows_max \(freeLimit)"))
                    .monoStyle(size: 9, color: .c2bMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // Title
            HStack(spacing: 0) {
                Text(String(localized: "free_select") + " ")
                    .displayStyle(size: 26, color: .c2bText)
                Text("\(stillOverCount > 0 ? stillOverCount : overCount)")
                    .displayStyle(size: 26, color: .c2bTeal)
                Text(" " + String(localized: "free_to_remove"))
                    .displayStyle(size: 26, color: .c2bText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Description
            Text(String(localized: "free_limit_description \(freeLimit)"))
                .uiStyle(size: 13, weight: .regular, color: .c2bDim)
                .lineSpacing(4)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Shows list
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(followedShows, id: \.self) { showId in
                        ShowRemovalCard(
                            showId: showId,
                            isMarked: markedForRemoval.contains(showId),
                            onToggle: {
                                if markedForRemoval.contains(showId) {
                                    markedForRemoval.remove(showId)
                                } else {
                                    markedForRemoval.insert(showId)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // Primary button
            Button(action: atLimit ? onContinue : (canRemove ? onCommit : {})) {
                Text(primaryButtonText)
                    .displayStyle(
                        size: 16,
                        color: atLimit ? Color(hex: "#04201c") : (canRemove ? Color(hex: "#1a0505") : .c2bMuted)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        atLimit ? Color.c2bTeal : (canRemove ? Color(hex: "#ff6b6b") : Color.white.opacity(0.07))
                    )
                    .cornerRadius(14)
            }
            .disabled(!atLimit && !canRemove)
            .padding(.horizontal, 20)

            // Upgrade link
            Button(action: onUpgrade) {
                Text(String(localized: "free_go_premium_keep \(followedShows.count)"))
                    .monoStyle(size: 10.5, color: .c2bTealBright)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 780)
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

    private var primaryButtonText: String {
        if atLimit {
            return String(localized: "free_continue_free")
        } else if markedForRemoval.count == 0 {
            return String(localized: "free_select_to_remove \(overCount)")
        } else if stillOverCount > 0 {
            return String(localized: "free_select_more \(stillOverCount)")
        } else {
            return String(localized: "free_remove_selected \(markedForRemoval.count)")
        }
    }
}

// MARK: - Show Removal Card
struct ShowRemovalCard: View {
    let showId: String
    let isMarked: Bool
    let onToggle: () -> Void

    private var showTitle: String {
        showId.replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 13) {
                // Poster
                Image(showId)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 46, height: 69)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .grayscale(isMarked ? 0.7 : 0)
                    .brightness(isMarked ? -0.45 : 0)
                    .animation(.easeOut(duration: 0.15), value: isMarked)

                // Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(showTitle)
                        .displayStyle(
                            size: 17,
                            color: isMarked ? .c2bMuted : .c2bText
                        )
                        .strikethrough(isMarked)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(isMarked ? String(localized: "free_marked_to_remove") : "S2 · PRIME")
                        .monoStyle(
                            size: 8.5,
                            color: isMarked ? Color(hex: "#ff6b6b") : .c2bMuted
                        )
                }

                Spacer()

                // Action icon
                ZStack {
                    Circle()
                        .fill(isMarked ? Color(hex: "#ff6b6b") : Color.white.opacity(0.06))
                        .frame(width: 34, height: 34)

                    Circle()
                        .stroke(
                            isMarked ? Color(hex: "#ff6b6b") : Color.white.opacity(0.16),
                            lineWidth: 1
                        )
                        .frame(width: 34, height: 34)

                    if isMarked {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(hex: "#1a0505"))
                    } else {
                        Image(systemName: "minus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#cfcfcf"))
                    }
                }
            }
            .padding(10)
            .background(
                isMarked ? Color(hex: "#ff6b6b").opacity(0.07) : Color.white.opacity(0.03)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isMarked ? Color(hex: "#ff6b6b").opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .animation(.easeOut(duration: 0.15), value: isMarked)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
