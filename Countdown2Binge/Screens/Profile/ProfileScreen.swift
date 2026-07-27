//
//  ProfileScreen.swift
//  Countdown2Binge
//
//  Main profile screen showing user info, stats, and followed shows.
//

import SwiftUI
import SwiftData

struct ProfileScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let isPremium: Bool

    private var profile: UserProfile { ProfileManager.shared.profile }
    @State private var followedShows: [FollowedShow] = []
    @State private var showEditProfile = false
    @State private var showShareSheet = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 12) {
                        // Back button
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#dddddd"))
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }

                        Text("header_profile")
                            .font(.custom(.oswald.bold, size: 24))
                            .tracking(0.48)
                            .foregroundColor(.white)

                        Spacer()

                        // Share button
                        Button(action: { showShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    // Identity card
                    ProfileIdentityCard(
                        profile: profile,
                        isPremium: isPremium,
                        onEditTap: { showEditProfile = true },
                        onShareTap: { showShareSheet = true }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // Tracked stats grid
                    ProfileTrackedStats(shows: followedShows)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Sync status
                    ProfileSyncStatus(
                        isPremium: isPremium,
                        showCount: followedShows.count,
                        lastSyncedAt: CloudSyncService.shared.lastSyncedAt
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                    // Shows list
                    VStack(spacing: 0) {
                        ForEach(followedShows, id: \.tmdbId) { show in
                            ProfileShowRow(
                                show: show,
                                isSynced: isPremium,
                                onTap: {
                                    // Navigate to show detail
                                }
                            )

                            if show.tmdbId != followedShows.last?.tmdbId {
                                Divider()
                                    .background(Color.white.opacity(0.06))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Sync footer
                    ProfileSyncFooter(
                        isPremium: isPremium,
                        showCount: followedShows.count,
                        lastSyncedAt: CloudSyncService.shared.lastSyncedAt
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    // Account settings button
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Text("profile_account_settings")
                                .font(.custom(.jetbrains.bold, size: 10.5))
                                .tracking(1.4)
                                .textCase(.uppercase)

                            Text("→")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.c2bMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .cornerRadius(13)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()
                        .frame(height: 150)
                }
            }
            .background(Color.c2bBackground)
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileScreen(isPremium: isPremium)
            }
            .overlay {
                if showShareSheet {
                    LineupShareSheet(
                        profile: profile,
                        shows: followedShows,
                        isPremium: isPremium,
                        onClose: { showShareSheet = false }
                    )
                }
            }
        }
    }

    private func loadData() {
        let store = FollowedShowsStore(modelContext: modelContext)
        followedShows = (try? store.getAllFollowed()) ?? []
    }
}

#Preview {
    ProfileScreen(isPremium: true)
        .preferredColorScheme(.dark)
}
