//
//  SwipeBackModifier.swift
//  Countdown2Binge
//
//  Global swipe-back gesture for views with hidden navigation bars.
//

import SwiftUI

// MARK: - Swipe Back Modifier

struct SwipeBackModifier: ViewModifier {
    let onDismiss: () -> Void
    let edgeWidth: CGFloat
    let minimumDistance: CGFloat

    init(
        onDismiss: @escaping () -> Void,
        edgeWidth: CGFloat = 50,
        minimumDistance: CGFloat = 80
    ) {
        self.onDismiss = onDismiss
        self.edgeWidth = edgeWidth
        self.minimumDistance = minimumDistance
    }

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Only trigger if started from left edge and swiped right far enough
                        if value.startLocation.x < edgeWidth && value.translation.width > minimumDistance {
                            onDismiss()
                        }
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    /// Adds swipe-back gesture for views with hidden navigation bars
    /// - Parameters:
    ///   - onDismiss: Action to perform when swipe is detected
    ///   - edgeWidth: How close to the left edge the swipe must start (default: 50pt)
    ///   - minimumDistance: Minimum swipe distance to trigger (default: 80pt)
    func swipeBack(
        onDismiss: @escaping () -> Void,
        edgeWidth: CGFloat = 50,
        minimumDistance: CGFloat = 80
    ) -> some View {
        modifier(SwipeBackModifier(
            onDismiss: onDismiss,
            edgeWidth: edgeWidth,
            minimumDistance: minimumDistance
        ))
    }

    /// Adds swipe-back gesture using environment dismiss
    func swipeBackToDismiss() -> some View {
        modifier(SwipeBackDismissModifier())
    }
}

// MARK: - Auto Dismiss Modifier

private struct SwipeBackDismissModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.startLocation.x < 50 && value.translation.width > 80 {
                            dismiss()
                        }
                    }
            )
    }
}
