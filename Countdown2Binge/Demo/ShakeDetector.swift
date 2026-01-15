//
//  ShakeDetector.swift
//  Countdown2Binge
//
//  Detects device shake gestures to toggle demo mode.
//

import SwiftUI
import UIKit

// MARK: - Shake Gesture Detection

/// Extension to detect shake motion events
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

// MARK: - Shake Gesture View Modifier

/// View modifier that responds to shake gestures
struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                action()
            }
    }
}

extension View {
    /// Perform an action when the device is shaken
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(ShakeGestureModifier(action: action))
    }
}

// MARK: - Demo Mode Overlay

/// A subtle overlay that shows when demo mode is active
struct DemoModeIndicator: View {
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            VStack {
                HStack {
                    Spacer()
                    Text("DEMO MODE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                        .padding(8)
                }
                Spacer()
            }
            .allowsHitTesting(false)
            .onAppear {
                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
}
