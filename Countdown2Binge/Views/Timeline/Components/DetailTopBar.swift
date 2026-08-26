//
//  DetailTopBar.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailTopBar: View {
    let onDismiss: () -> Void
    var onShare: (() -> Void)? = nil
    var show: ShowData? = nil
    var onUnfollow: (() -> Void)? = nil
    var isArchived: Bool = false
    var onArchive: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showUnfollowConfirmation = false
    @State private var showArchiveConfirmation = false

    private var streamingService: StreamingService? {
        guard let show = show, let network = show.networks.first else { return nil }
        return StreamingService.from(networkId: network.id, networkName: network.name)
    }

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Button {
                    dismiss()
                } label: {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 38, height: 38)
                        .overlay(
                            DirectionalIcon(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }

                Spacer()

                DetailFollowingBadge()

                // Menu button (replaces share button when show data is available)
                if show != nil || onShare != nil {
                    Menu {
                        // Watch Now section
                        if let service = streamingService, let show = show {
                            Section {
                                Button {
                                    openStreamingApp(service: service, showName: show.name)
                                } label: {
                                    Label(
                                        String(localized: "watch_on \(service.displayName)"),
                                        systemImage: "play.tv"
                                    )
                                }
                            }
                        }

                        // Share
                        if let onShare = onShare {
                            Button {
                                onShare()
                            } label: {
                                Label(String(localized: "button_share"), systemImage: "square.and.arrow.up")
                            }
                        }

                        // Archive/Unarchive
                        if onArchive != nil, show != nil {
                            Button {
                                showArchiveConfirmation = true
                            } label: {
                                Label(
                                    isArchived
                                        ? String(localized: "button_unarchive")
                                        : String(localized: "button_archive"),
                                    systemImage: isArchived ? "arrow.uturn.backward" : "archivebox"
                                )
                            }
                        }

                        // Unfollow (destructive)
                        if onUnfollow != nil, show != nil {
                            Section {
                                Button(role: .destructive) {
                                    showUnfollowConfirmation = true
                                } label: {
                                    Label(
                                        String(localized: "button_unfollow"),
                                        systemImage: "xmark.circle"
                                    )
                                }
                            }
                        }
                    } label: {
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                    // Both dialogs hang off the Menu that raises them. On the
                    // outer VStack — which fills the screen behind a Spacer —
                    // iOS 26 anchored them to the whole page and parked the
                    // bubble in mid-air.
                    .confirmationDialog(
                        isArchived
                            ? String(localized: "alert_unarchive_title")
                            : String(localized: "alert_archive_title"),
                        isPresented: $showArchiveConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(isArchived ? String(localized: "button_unarchive") : String(localized: "button_archive")) {
                            onArchive?()
                        }
                        Button(String(localized: "button_cancel"), role: .cancel) {}
                    } message: {
                        Text(isArchived ? "alert_unarchive_message" : "alert_archive_message")
                    }
                    .confirmationDialog(
                        String(localized: "alert_unfollow \(show?.name ?? "")"),
                        isPresented: $showUnfollowConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(String(localized: "button_unfollow"), role: .destructive) {
                            onUnfollow?()
                        }
                        Button(String(localized: "button_cancel"), role: .cancel) {}
                    } message: {
                        Text("alert_remove_message")
                    }                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 52)

            Spacer()
        }
    }

    private func openStreamingApp(service: StreamingService, showName: String) {
        // Try deep link first, fall back to web URL
        if let deepLink = service.deepLinkURL(for: showName),
           UIApplication.shared.canOpenURL(deepLink) {
            openURL(deepLink)
        } else if let webURL = service.webURL(for: showName) {
            openURL(webURL)
        }
    }
}
