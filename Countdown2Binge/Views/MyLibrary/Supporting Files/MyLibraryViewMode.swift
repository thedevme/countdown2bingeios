//
//  MyLibraryViewMode.swift
//  Countdown2Binge
//
//  Grid vs list display for My Library's shows.
//

import SwiftUI

enum MyLibraryViewMode {
    case grid
    case list
}

/// The two-icon segmented toggle, top-right of the "MY LIBRARY" header.
struct MyLibraryViewModeToggle: View {
    @Binding var mode: MyLibraryViewMode

    var body: some View {
        HStack(spacing: 4) {
            button(.grid, systemImage: "square.grid.2x2")
            button(.list, systemImage: "line.3.horizontal")
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func button(_ target: MyLibraryViewMode, systemImage: String) -> some View {
        let isOn = mode == target
        return Button(action: { mode = target }) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isOn ? .c2bOnTeal : .white.opacity(0.4))
                .frame(width: 36, height: 36)
                .background(isOn ? Color.c2bTeal : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct Wrapper: View {
        @State var mode: MyLibraryViewMode = .grid
        var body: some View {
            MyLibraryViewModeToggle(mode: $mode)
        }
    }
    return Wrapper()
        .padding()
        .background(Color.c2bBackground)
}
