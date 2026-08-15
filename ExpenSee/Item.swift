//
//  Item.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
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
