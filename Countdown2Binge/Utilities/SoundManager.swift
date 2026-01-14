//
//  SoundManager.swift
//  Countdown2Binge
//

import AVFoundation
import UIKit

/// Manages sound effects for the app
final class SoundManager {
    static let shared = SoundManager()

    private var cardSwipePlayer: AVAudioPlayer?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    private init() {
        // Configure audio session for playback
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        // Preload sounds
        preloadSounds()

        // Prepare haptic
        hapticGenerator.prepare()
    }

    private func preloadSounds() {
        guard let url = Bundle.main.url(forResource: "cardswipe", withExtension: "wav") else {
            print("Sound file not found")
            return
        }

        do {
            cardSwipePlayer = try AVAudioPlayer(contentsOf: url)
            cardSwipePlayer?.volume = 0.3
            cardSwipePlayer?.prepareToPlay()
        } catch {
            print("Failed to load sound: \(error)")
        }
    }

    /// Play the card swipe sound
    func playCardSwipe() {
        cardSwipePlayer?.currentTime = 0
        cardSwipePlayer?.play()
    }

    /// Play card swipe with haptic feedback
    func playCardSwipeWithHaptic() {
        playCardSwipe()
        hapticGenerator.impactOccurred()
        hapticGenerator.prepare() // Prepare for next use
    }

    /// Call early to preload all sounds
    static func warmUp() {
        _ = shared
    }
}
