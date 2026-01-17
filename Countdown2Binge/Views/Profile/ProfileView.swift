//
//  ProfileView.swift
//  Countdown2Binge
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.15))

                    Text("Coming Soon")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Your profile and stats")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    Text("PROFILE")
                        .font(.system(size: 36, weight: .heavy, design: .default).width(.condensed))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .toolbarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
