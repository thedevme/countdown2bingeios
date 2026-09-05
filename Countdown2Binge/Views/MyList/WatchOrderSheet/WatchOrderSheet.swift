//
//  WatchOrderSheet.swift
//  Countdown2Binge
//
//  Bottom sheet for reordering Straight Through's "Upcoming" section — the
//  shows queued behind Next. Up/down only (no drag), same as the design.
//  A custom order only ever reshuffles what's queued BEHIND Next; Next
//  itself is never part of this list. Design ref: "My List Cards.html" —
//  `reorderSheet()`.
//

import SwiftUI

struct WatchOrderSheet: View {
    /// The Upcoming section's items, in their CURRENT displayed order
    /// (default "shortest first", or already-custom) — this is both what's
    /// rendered and the base order `WatchOrderStore.move` swaps within.
    let items: [(id: Int, posterURL: URL?, title: String, secondsLeft: Int)]
    let tone: Color

    @State private var orderStore = WatchOrderStore.shared

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            Text("WATCH ORDER")
                .font(.custom(.oswald.bold, size: 20))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundColor(.c2bText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("DRAG-FREE · MOVE A SHOW UP OR DOWN")
                .font(.custom(.jetbrains.bold, size: 8))
                .tracking(1.5)
                .foregroundColor(.c2bMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
                .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        WatchOrderRow(
                            position: index + 1,
                            posterURL: item.posterURL,
                            title: item.title,
                            timeLeftText: clockText(item.secondsLeft),
                            tone: tone,
                            isFirst: index == 0,
                            isLast: index == items.count - 1,
                            onMoveUp: { move(id: item.id, direction: -1) },
                            onMoveDown: { move(id: item.id, direction: 1) }
                        )
                    }
                }
            }

            HStack(spacing: 9) {
                if orderStore.customOrder != nil {
                    Button(action: { orderStore.reset() }) {
                        Text("RESET")
                            .font(.custom(.oswald.bold, size: 14))
                            .tracking(0.5)
                            .foregroundColor(.c2bDim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { dismiss() }) {
                    Text("DONE")
                        .font(.custom(.oswald.bold, size: 14))
                        .tracking(0.5)
                        .foregroundColor(.c2bOnTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.c2bTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
        .background(Color.c2bCard)
    }

    @Environment(\.dismiss) private var dismissAction
    private func dismiss() { dismissAction() }

    private func move(id: Int, direction: Int) {
        orderStore.move(id: id, direction: direction, within: items.map(\.id))
    }

    private func clockText(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return "\(h)h:\(String(format: "%02d", m))m:\(String(format: "%02d", s))s"
    }
}

#Preview {
    Color.c2bBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            WatchOrderSheet(
                items: [
                    (1, nil, "Redwood Falls", 5 * 3600 + 12 * 60),
                    (2, nil, "Forward Hold", 6 * 3600 + 14 * 60 + 56),
                    (3, nil, "Echo 7", 7 * 3600 + 27 * 60 + 50),
                    (4, nil, "Iron Veil", 101 * 3600 + 6 * 60 + 54),
                ],
                tone: Color(hex: "#A38CF3")
            )
            .presentationDetents([.large])
            .presentationCornerRadius(24)
            .presentationDragIndicator(.hidden)
        }
}
