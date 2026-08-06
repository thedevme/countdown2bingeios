import SwiftUI

struct TimelineBucketLabel: View {
    let label: String
    let tone: Color
    let isActive: Bool
    let isDone: Bool

    private var isOn: Bool { isActive || isDone }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            // Bullet point
            ZStack {
                Circle()
                    .fill(isOn ? tone : Color(hex: "#18181b"))
                    .frame(width: 12, height: 12)

                if !isOn {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                        .frame(width: 12, height: 12)
                }

                if isActive {
                    Circle()
                        .stroke(
                            tone.opacity(0.25),
                            lineWidth: 8
                        )
                        .frame(width: 12, height: 12)
                }
            }
            .frame(width: 12, height: 12)
            .fixedSize()
            .clipped()
            .padding(.top, 4)

            // Label
            Text(label)
                .font(.custom(.oswald.bold, size: CustomFont.size.body))
                .foregroundColor(isOn ? tone : Color(hex: "#52525b"))
                .textCase(.uppercase)
                .tracking(0.3)
        }
    }
}
