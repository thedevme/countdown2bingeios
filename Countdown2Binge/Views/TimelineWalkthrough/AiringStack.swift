import SwiftUI

// MARK: - Airing Stack (Card stack with rotation)
struct AiringStack: View {
    let shows: [String]
    let bucketKey: String
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            // Card 4 (back-most, only if 4 shows)
            if shows.count > 3 {
                Image(shows[3])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .matchedGeometryEffect(id: shows[3], in: namespace)
                    .brightness(-0.4)
                    .opacity(0.5)
                    .rotationEffect(.degrees(-10))
                    .offset(x: -50, y: 4)
                    .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 8)
                    .zIndex(0)
            }

            // Card 3
            if shows.count > 2 {
                Image(shows[2])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .matchedGeometryEffect(id: shows[2], in: namespace)
                    .brightness(-0.35)
                    .opacity(0.6)
                    .rotationEffect(.degrees(8))
                    .offset(x: 36, y: 2)
                    .shadow(color: Color.black.opacity(0.6), radius: 16, x: 0, y: 10)
                    .zIndex(1)
            }

            // Card 2
            if shows.count > 1 {
                Image(shows[1])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 110, height: 165)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .matchedGeometryEffect(id: shows[1], in: namespace)
                    .brightness(-0.3)
                    .opacity(0.75)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -38, y: 1)
                    .shadow(color: Color.black.opacity(0.6), radius: 16, x: 0, y: 10)
                    .zIndex(2)
            }

            // Card 1 (top card)
            if !shows.isEmpty {
                Image(shows[0])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 118, height: 176)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .matchedGeometryEffect(id: shows[0], in: namespace)
                    .shadow(color: Color.black.opacity(0.7), radius: 20, x: 0, y: 12)
                    .zIndex(3)
            }
        }
        .frame(height: 188)
        .padding(.vertical, 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: shows)
    }
}

// Preview disabled - requires namespace parameter
// #Preview {
//     AiringStack(shows: ["the-last-of-us", "severance", "the-bear"])
//         .padding()
//         .background(Color(hex: "#0c0c0e"))
// }
