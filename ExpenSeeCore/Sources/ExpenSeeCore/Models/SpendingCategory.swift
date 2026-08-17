//
//  SpendingCategory.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import SwiftData

@Model
public final class SpendingCategory {
    public var id: UUID
    public var name: String
    public var hexColor: String
    public var iconString: String
    
    public init(id: UUID = UUID(), name: String, hexColor: String, iconString: String = "cart") {
        self.id = id
        self.name = name
        self.hexColor = hexColor
        self.iconString = iconString
    }
}
