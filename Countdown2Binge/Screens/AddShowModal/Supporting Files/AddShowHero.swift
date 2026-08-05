//
//  AddShowHero.swift
//  Countdown2Binge
//
//  Hero section with backdrop, badge, and show title.
//

import SwiftUI

struct AddShowHero: View {
    let showName: String
    let backdropURL: URL?
    let posterURL: URL?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: backdropURL ?? posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                default:
                    Rectangle()
                        .fill(Color.c2bSurface)
                        .frame(height: 160)
                }
            }
            .frame(height: 160)

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color(hex: "#0e0e0f"),
                    Color(hex: "#0e0e0f").opacity(0.6),
                    Color(hex: "#0e0e0f").opacity(0.2)
                ],
                startPoint: .bottom,
                endPoint: .top
            )

            // Content
            VStack(alignment: .leading, spacing: 10) {
                // Badge
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#04201c"))

                    Text("add_show_badge")
                        .font(.custom(.jetbrains.bold, size: 8.5))
                        .tracking(1.02)
                        .foregroundColor(Color(hex: "#04201c"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.c2bTeal)
                .clipShape(Capsule())

                // Show title
                Text(showName.uppercased())
                    .font(.custom(.oswald.bold, size: 28))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 10, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(height: 160)
    }
}

#Preview {
    AddShowHero(
        showName: "Vice Coast",
        backdropURL: nil,
        posterURL: nil
    )
    .background(Color.c2bBackground)
}
