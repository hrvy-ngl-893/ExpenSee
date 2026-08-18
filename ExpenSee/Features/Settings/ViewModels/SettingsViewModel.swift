//
//  SettingsViewModel.swift
//  ExpenSee
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    public var id: String { rawValue }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

private let sharedUserDefaults = UserDefaults(suiteName: "group.com.harvy-angelo-tan.ExpenSee")

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("userCurrencyCode", store: sharedUserDefaults)
    public var currencyCode: String = Locale.current.currency?.identifier ?? "USD" {
        willSet {
            objectWillChange.send()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @AppStorage("notificationsEnabled", store: sharedUserDefaults)
    public var notificationsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    
    @AppStorage("appThemeRaw", store: sharedUserDefaults)
    public var appThemeRaw: String = AppTheme.system.rawValue {
        willSet {
            objectWillChange.send()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @AppStorage("liveActivityEnabled", store: sharedUserDefaults)
    public var liveActivityEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    
    public var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .system }
        set { appThemeRaw = newValue.rawValue }
    }
    
    public init() {}
}
