//
//  CountdownDisplayMode.swift
//  Countdown2Binge
//

enum CountdownDisplayMode: String, CaseIterable {
    case days
    case episodes

    var label: String {
        switch self {
        case .days: return "Days"
        case .episodes: return "Episodes"
        }
    }

    var unit: String {
        switch self {
        case .days: return "DAYS"
        case .episodes: return "EPS"
        }
    }
}
