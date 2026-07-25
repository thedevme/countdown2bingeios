//
//  CountdownDisplayMode.swift
//  Countdown2Binge
//

import Foundation

enum CountdownDisplayMode: String, CaseIterable {
    case days
    case episodes

    var label: String {
        switch self {
        case .days: return String(localized: "countdown_mode_days")
        case .episodes: return String(localized: "countdown_mode_episodes")
        }
    }

    var unit: String {
        switch self {
        case .days: return String(localized: "time_days")
        case .episodes: return String(localized: "label_eps")
        }
    }
}
