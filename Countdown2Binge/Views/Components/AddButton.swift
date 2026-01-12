//
//  AddButton.swift
//  Countdown2Binge
//

import SwiftUI

/// A button for adding/removing shows from the followed list.
/// Displays "+ Add" when not following, "Added" with checkmark when following.
struct AddButton: View {
    let isAdded: Bool
    let isLoading: Bool
    let action: () -> Void

    init(isAdded: Bool, isLoading: Bool = false, action: @escaping () -> Void) {
        self.isAdded = isAdded
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(isAdded ? addedForeground : addForeground)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(isAdded ? "Added" : "Add")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isAdded ? addedForeground : addForeground)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isAdded ? addedBackground : addBackground)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isAdded ? addedBorder : addBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isAdded)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }

    // MARK: - Colors

    // "Add" state - prominent call to action
    private var addForeground: Color {
        .white
    }

    private var addBackground: Color {
        Color(red: 0.35, green: 0.55, blue: 0.85)
    }

    private var addBorder: Color {
        Color(red: 0.45, green: 0.65, blue: 0.95)
    }

    // "Added" state - subtle confirmation
    private var addedForeground: Color {
        Color(red: 0.45, green: 0.90, blue: 0.70)
    }

    private var addedBackground: Color {
        Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.12)
    }

    private var addedBorder: Color {
        Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.4)
    }
}

// MARK: - Compact Variant

/// A smaller, icon-only variant for tight spaces
struct AddButtonCompact: View {
    let isAdded: Bool
    let isLoading: Bool
    let action: () -> Void

    init(isAdded: Bool, isLoading: Bool = false, action: @escaping () -> Void) {
        self.isAdded = isAdded
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(isAdded ? addedColor : addColor)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isAdded ? addedColor : addColor)
                }
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isAdded)
    }

    private var addColor: Color {
        Color(red: 0.35, green: 0.55, blue: 0.85)
    }

    private var addedColor: Color {
        Color(red: 0.45, green: 0.90, blue: 0.70)
    }
}

// MARK: - Preview

#Preview("Add Button States") {
    VStack(spacing: 24) {
        AddButton(isAdded: false) { }
        AddButton(isAdded: true) { }
        AddButton(isAdded: false, isLoading: true) { }
        AddButton(isAdded: true, isLoading: true) { }
    }
    .padding(32)
    .background(Color(white: 0.08))
}

#Preview("Compact Variant") {
    HStack(spacing: 24) {
        AddButtonCompact(isAdded: false) { }
        AddButtonCompact(isAdded: true) { }
        AddButtonCompact(isAdded: false, isLoading: true) { }
    }
    .padding(32)
    .background(Color(white: 0.08))
}

#Preview("On Search Result") {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text("Severance")
                .font(.headline)
                .foregroundStyle(.white)
            Text("2022 • Drama")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }

        Spacer()

        AddButton(isAdded: false) { }
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.12))
    )
    .padding(24)
    .background(Color.black)
}
