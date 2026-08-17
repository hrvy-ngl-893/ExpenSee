//
//  SettingsViewModel.swift
//  ExpenSee
//

import Foundation
import SwiftUI
import Combine

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

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("userCurrencyCode") public var currencyCode: String = Locale.current.currency?.identifier ?? "USD" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") public var notificationsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("appThemeRaw") public var appThemeRaw: String = AppTheme.system.rawValue {
        willSet { objectWillChange.send() }
    }
    @AppStorage("liveActivityEnabled") public var liveActivityEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    
    public var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .system }
        set { appThemeRaw = newValue.rawValue }
    }
    
    public init() {}
}
