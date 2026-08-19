//
//  ExpenSeeWidgetBundle.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/16/26.
//

import WidgetKit
import SwiftUI

@main
struct ExpenSeeWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpendingWidget()
        QuickLogWidget()
        
        #if os(iOS)
        LiveActivity()
        #endif
    }
}
