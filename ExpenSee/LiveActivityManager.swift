//
//  LiveActivityManager.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import Combine
import ExpenSeeCore

#if os(iOS) && canImport(ActivityKit)
import ActivityKit

@MainActor
public final class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()
    
    @Published public private(set) var currentActivity: Activity<SpendingActivityAttributes>?
    
    private init() {
        // Restore active activity reference if one is already running
        currentActivity = Activity<SpendingActivityAttributes>.activities.first
    }
    
    /// Starts a new Live Activity for spending track
    public func startActivity(
        remainingBudget: Decimal,
        spentToday: Decimal,
        baseDailyLimit: Decimal,
        budgetCycleName: String = "Daily Budget"
    ) {
        // Prevent starting duplicate activities if disabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = SpendingActivityAttributes(budgetCycleName: budgetCycleName)
        let initialState = SpendingActivityAttributes.ContentState(
            remainingBudget: remainingBudget,
            spentToday: spentToday,
            baseDailyLimit: baseDailyLimit,
            lastExpenseAmount: nil,
            lastExpenseCategory: nil
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    /// Updates the active Live Activity content state
    public func updateActivity(
        remainingBudget: Decimal,
        spentToday: Decimal,
        baseDailyLimit: Decimal,
        lastExpenseAmount: Decimal? = nil,
        lastExpenseCategory: String? = nil
    ) {
        guard let activity = currentActivity else { return }
        
        let updatedState = SpendingActivityAttributes.ContentState(
            remainingBudget: remainingBudget,
            spentToday: spentToday,
            baseDailyLimit: baseDailyLimit,
            lastExpenseAmount: lastExpenseAmount,
            lastExpenseCategory: lastExpenseCategory
        )
        
        Task {
            await activity.update(
                ActivityContent<SpendingActivityAttributes.ContentState>(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }
    
    /// Ends the current active Live Activity
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
            }
        }
    }

}
#endif
