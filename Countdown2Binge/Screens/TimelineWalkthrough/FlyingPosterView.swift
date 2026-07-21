import SwiftUI

struct FlyingPosterView: View {
    let flying: FlyingPoster
    let namespace: Namespace.ID

    var body: some View {
        Image(flying.showId)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 118, height: 176)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .matchedGeometryEffect(id: flying.showId, in: namespace)
            .shadow(color: Color.black.opacity(0.7), radius: 20, x: 0, y: 12)
    }
}
