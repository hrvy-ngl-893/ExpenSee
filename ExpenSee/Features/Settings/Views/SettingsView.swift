//
//  SettingsView.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Currency", selection: $viewModel.currencyCode) {
                        Text("USD ($)").tag("USD")
                        Text("EUR (€)").tag("EUR")
                        Text("PHP (₱)").tag("PHP")
                        Text("GBP (£)").tag("GBP")
                        Text("JPY (¥)").tag("JPY")
                    }
                    
                    Picker("Appearance", selection: Binding(
                        get: { viewModel.appTheme },
                        set: { viewModel.appTheme = $0 }
                    )) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                
                Section("Notifications & Live Activities") {
                    Toggle("Recurring Payment Reminders", isOn: $viewModel.notificationsEnabled)
                    Toggle("Enable Live Activity Tracking", isOn: $viewModel.liveActivityEnabled)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    NavigationStack{
        SettingsView()
            .environmentObject(SettingsViewModel())
    }
}
