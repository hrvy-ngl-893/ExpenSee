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
        case transaction
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
                    Label("Accounts", systemImage: "creditcard.fill")
                }
                .tag(Tab.sources)
            
            
            
            TransactionView()
                .tabItem {
                    Label("Transaction", systemImage: "dollarsign.arrow.circlepath")
                }
                .tag(Tab.transaction)
            
            SpendingLimitView()
                .tabItem {
                    Label("Budgets", systemImage: "dollarsign.circle.fill")
                }
                .tag(Tab.transaction)
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie")
                }
                .tag(Tab.analytics)
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
