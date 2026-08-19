//
//  ContentView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI
import SwiftData
import ExpenSeeCore

struct ContentView: View {
    enum Tab: Hashable {
        case dashboard
        case analytics
        case sources
        case settings
    }
    
    @Binding var showAddExpenseSheet: Bool
    @State private var selectedTab: Tab = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
                .tag(Tab.dashboard)
            
            AccountsView()
                .tabItem {
                    Label("Source", systemImage: "creditcard.fill")
                }
                .tag(Tab.sources)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie")
                }
                .tag(Tab.analytics)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView(showAddExpenseSheet: .constant(false))
        .modelContainer(ModelContainerFactory.inMemoryPreview)
        #if os(iOS)
        .environmentObject(LiveActivityManager.shared)
        #endif
        .environmentObject(SettingsViewModel())
}
