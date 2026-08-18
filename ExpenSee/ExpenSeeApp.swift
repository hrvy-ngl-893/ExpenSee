//
//  ExpenSeeApp.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

@main
struct ExpenSeeApp: App {
    private let container = ModelContainerFactory.shared
    
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @StateObject private var settings = SettingsViewModel()
    @State private var showAddExpenseSheet = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(showAddExpenseSheet: $showAddExpenseSheet)
                .modelContainer(container)
                .environmentObject(liveActivityManager)
                .environmentObject(settings)
                .preferredColorScheme(settings.appTheme.colorScheme)
                .onOpenURL { url in
                    if url.scheme == "expen-see" && (url.host == "add-expense" || url.host == "log") {
                        showAddExpenseSheet = true
                    }
                }
        }
    }
}

#Preview {
    ContentView(showAddExpenseSheet: .constant(false))
        .modelContainer(ModelContainerFactory.inMemoryPreview)
        .environmentObject(LiveActivityManager.shared)
        .environmentObject(SettingsViewModel())
}
