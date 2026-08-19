//
//  LiveActivityManager.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import Combine
import ExpenSeeCore
import WidgetKit

#if os(iOS) && canImport(ActivityKit)
import ActivityKit

@MainActor
public final class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()
    
    @Published public private(set) var currentActivity: Activity<LiveActivityAttributes>?
    
    private init() {
        // Restore reference if an activity is already running on app launch
        currentActivity = Activity<LiveActivityAttributes>.activities.first(where: { $0.activityState == .active })
    }
    
    /// Starts or updates a Live Activity for the selected budget and reloads widget timelines.
    public func updateOrStartActivity(
        remainingBudget: Decimal,
        spentToday: Decimal,
        baseDailyLimit: Decimal,
        budgetCycleName: String,
        currencyCode: String,
        lastExpenseAmount: Decimal? = nil,
        lastExpenseCategory: String? = nil
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let state = LiveActivityAttributes.ContentState(
            remainingBudget: remainingBudget,
            spentToday: spentToday,
            baseDailyLimit: baseDailyLimit,
            currencyCode: currencyCode,
            lastExpenseAmount: lastExpenseAmount,
            lastExpenseCategory: lastExpenseCategory
        )
        
        // If an activity is already active with a matching budget cycle name, update it.
        if let activity = currentActivity, activity.activityState == .active {
            if activity.attributes.budgetCycleName == budgetCycleName {
                Task {
                    // Alert configuration signals high priority update to Dynamic Island
                    let alertConfig = AlertConfiguration(
                        title: "\(currencyCode) Updated",
                        body: "Currency updated in Live Activity",
                        sound: .default
                    )
                    
                    await activity.update(
                        ActivityContent<LiveActivityAttributes.ContentState>(
                            state: state,
                            staleDate: nil
                        ),
                        alertConfiguration: alertConfig
                    )
                    WidgetCenter.shared.reloadAllTimelines()
                }
                return
            } else {
                // If the selected budget changed, end the current activity first to apply new attributes.
                endActivitySync()
            }
        }
        
        // Request a new activity if none is active or if the budget title changed
        let attributes = LiveActivityAttributes(budgetCycleName: budgetCycleName)
        do {
            let newActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = newActivity
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    /// Ends the active Live Activity immediately.
    public func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            let finalContent = ActivityContent(
                state: activity.content.state,
                staleDate: nil
            )
            await activity.end(finalContent, dismissalPolicy: .immediate)
            
            await MainActor.run {
                self.currentActivity = nil
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    /// Synchronous internal helper to end stale activities before switching budgets.
    private func endActivitySync() {
        guard let activity = currentActivity else { return }
        let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
        
        Task {
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
    }
}
#endif
