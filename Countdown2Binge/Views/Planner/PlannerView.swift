//
//  PlannerView.swift
//  Countdown2Binge
//

import SwiftUI

struct PlannerView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.15))

                    Text("Coming Soon")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Plan your binge sessions")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    Text("PLANNER")
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
    PlannerView()
        .preferredColorScheme(.dark)
}
