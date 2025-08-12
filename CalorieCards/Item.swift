//
//  Item.swift
//  CalorieCards
//
//  Created by Tairan Wang on 12/8/2025.
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
