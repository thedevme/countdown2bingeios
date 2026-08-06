//
//  DiscoverNetworkContent.swift
//  Countdown2Binge
//

import SwiftUI

struct DiscoverNetworkContent: View {
    let viewModel: DiscoverViewModel
    let selectedNetwork: String
    let onShowTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    var body: some View {
        if selectedNetwork == "all" {
            VStack(spacing: 32) {
                ForEach(DiscoverViewModel.networks) { network in
                    DiscoverNetworkSection(
                        network: network,
                        shows: viewModel.networkShows[network.id] ?? [],
                        isFollowing: { viewModel.isFollowing($0) },
                        onShowTap: onShowTap,
                        onFollowTap: onFollowTap
                    )
                }
            }
        } else if let networkId = Int(selectedNetwork),
                  let network = DiscoverViewModel.networks.first(where: { $0.id == networkId }) {
            DiscoverNetworkSection(
                network: network,
                shows: viewModel.networkShows[networkId] ?? [],
                isFollowing: { viewModel.isFollowing($0) },
                onShowTap: onShowTap,
                onFollowTap: onFollowTap
            )
        }
    }
}
