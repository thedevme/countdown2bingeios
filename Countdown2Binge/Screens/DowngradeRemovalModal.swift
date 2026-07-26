//
//  DowngradeRemovalModal.swift
//  Countdown2Binge
//
//  Modal that appears when premium user downgrades to free
//  and has more than 3 shows. Forces removal until at limit.
//

import SwiftUI
import SwiftData

struct DowngradeRemovalModal: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext

    @State private var followedShows: [FollowedShow] = []
    @State private var markedForRemoval: Set<Int> = [] // tmdbIds
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
            // Backdrop - not dismissable
            Color.black
                .opacity(showOverlay ? 0.85 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.35), value: showOverlay)

            // Bottom sheet
            VStack {
                Spacer()

                DowngradeRemovalSheet(
                    followedShows: followedShows,
                    markedForRemoval: $markedForRemoval,
                    freeLimit: freeLimit,
                    overCount: overCount,
                    stillOverCount: stillOverCount,
                    canRemove: canRemove,
                    atLimit: atLimit,
                    onCommit: commitRemoval,
                    onUpgrade: handleUpgrade
                )
                .offset(y: showSheet ? 0 : 1000)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showSheet)
            }
        }
        .onAppear {
            loadFollowedShows()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                showOverlay = true
                showSheet = true
            }
        }
    }

    private func loadFollowedShows() {
        let store = FollowedShowsStore(modelContext: modelContext)
        followedShows = (try? store.getAllFollowed()) ?? []
    }

    private func commitRemoval() {
        let store = FollowedShowsStore(modelContext: modelContext)
        let seriesStore = SeriesStore(modelContext: modelContext)

        for tmdbId in markedForRemoval {
            do {
                try store.unfollow(tmdbId: tmdbId)
                try seriesStore.delete(tmdbId: tmdbId)

                // Remove from cloud (will be skipped if not premium)
                Task { await CloudSyncService.shared.removeShow(tmdbId: tmdbId) }
            } catch {
                print("Error removing show \(tmdbId): \(error)")
            }
        }

        // Reload and check if at limit
        loadFollowedShows()
        markedForRemoval.removeAll()

        // Clear downgrade flag and grace period
        PremiumManager.shared.didDowngradeFromPremium = false
        Task {
            await PremiumManager.shared.clearGracePeriod()
        }

        if atLimit {
            dismissModal()
        }
    }

    private func handleUpgrade() {
        // Clear the flags and dismiss - user will go to paywall
        PremiumManager.shared.didDowngradeFromPremium = false
        Task {
            await PremiumManager.shared.clearGracePeriod()
        }
        dismissModal()
        // TODO: Present paywall
    }

    private func dismissModal() {
        showSheet = false
        showOverlay = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            isPresented = false
        }
    }
}

// MARK: - Sheet Content
private struct DowngradeRemovalSheet: View {
    let followedShows: [FollowedShow]
    @Binding var markedForRemoval: Set<Int>
    let freeLimit: Int
    let overCount: Int
    let stillOverCount: Int
    let canRemove: Bool
    let atLimit: Bool
    let onCommit: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle (visual only - not dismissable)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 18)

            // Header badges
            HStack(spacing: 9) {
                Text("free_plan_badge")
                    .font(.custom(.jetbrains.bold, size: 9))
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "#04201c"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.c2bMuted)
                    .cornerRadius(999)

                Text(String(localized: "free_shows_max \(freeLimit)"))
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(1.2)
                    .foregroundColor(.c2bMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // Title
            if atLimit {
                Text("downgrade_all_set")
                    .font(.custom(.oswald.bold, size: 26))
                    .foregroundColor(.c2bTeal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            } else {
                HStack(spacing: 0) {
                    Text(String(localized: "downgrade_remove") + " ")
                        .font(.custom(.oswald.bold, size: 26))
                        .foregroundColor(.c2bText)
                    Text("\(stillOverCount > 0 ? stillOverCount : overCount)")
                        .font(.custom(.oswald.bold, size: 26))
                        .foregroundColor(Color(hex: "#ff6b6b"))
                    Text(" " + String(localized: "downgrade_to_continue"))
                        .font(.custom(.oswald.bold, size: 26))
                        .foregroundColor(.c2bText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // Description
            Text(atLimit
                 ? String(localized: "downgrade_at_limit")
                 : String(localized: "downgrade_over_limit \(freeLimit)"))
                .font(.system(size: 13))
                .foregroundColor(.c2bDim)
                .lineSpacing(4)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Shows list
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(followedShows, id: \.tmdbId) { show in
                        DowngradeShowCard(
                            show: show,
                            isMarked: markedForRemoval.contains(show.tmdbId),
                            onToggle: {
                                if markedForRemoval.contains(show.tmdbId) {
                                    markedForRemoval.remove(show.tmdbId)
                                } else {
                                    markedForRemoval.insert(show.tmdbId)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // Primary button
            Button(action: atLimit ? onCommit : (canRemove ? onCommit : {})) {
                Text(primaryButtonText)
                    .font(.custom(.oswald.bold, size: 16))
                    .foregroundColor(
                        atLimit ? Color(hex: "#04201c") : (canRemove ? Color(hex: "#1a0505") : .c2bMuted)
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
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                    Text(String(localized: "downgrade_resubscribe \(followedShows.count)"))
                        .font(.custom(.jetbrains.bold, size: 10.5))
                        .tracking(0.8)
                }
                .foregroundColor(.c2bTealBright)
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
            return String(localized: "button_continue")
        } else if markedForRemoval.count == 0 {
            return String(localized: "free_select_to_remove \(overCount)")
        } else if stillOverCount > 0 {
            return String(localized: "free_select_more \(stillOverCount)")
        } else {
            return String(localized: "free_remove_selected \(markedForRemoval.count)")
        }
    }
}

// MARK: - Show Card
private struct DowngradeShowCard: View {
    let show: FollowedShow
    let isMarked: Bool
    let onToggle: () -> Void

    private var showName: String {
        show.cachedData?.name ?? "Show \(show.tmdbId)"
    }

    private var posterURL: URL? {
        guard let path = show.cachedData?.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(path)")
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 13) {
                // Poster
                AsyncImage(url: posterURL) { phase in
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
                .frame(width: 46, height: 69)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .grayscale(isMarked ? 0.7 : 0)
                .brightness(isMarked ? -0.45 : 0)
                .animation(.easeOut(duration: 0.15), value: isMarked)

                // Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(showName)
                        .font(.custom(.oswald.bold, size: 17))
                        .foregroundColor(isMarked ? .c2bMuted : .c2bText)
                        .strikethrough(isMarked)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(isMarked ? String(localized: "free_marked_remove") : String(localized: "downgrade_followed \(formattedDate)"))
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(0.8)
                        .foregroundColor(isMarked ? Color(hex: "#ff6b6b") : .c2bMuted)
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

    private var formattedDate: String {
        show.followedAt.localizedShortDate
    }
}
