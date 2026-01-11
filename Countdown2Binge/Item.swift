//
//  Item.swift
//  Countdown2Binge
//
//  Created by Craig Clayton on 1/11/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
