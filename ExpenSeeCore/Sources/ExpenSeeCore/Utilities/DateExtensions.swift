//
//  DateExtensions.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI

public extension Date {
    static func daysAgo(_ days: Int, hour: Int = 12, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
}
