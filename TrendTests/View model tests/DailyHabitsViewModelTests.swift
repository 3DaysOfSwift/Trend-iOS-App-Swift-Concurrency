// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct DailyHabitsViewModelTests {
    @Test func lockedTodayCannotRecordAPaidHabit() async throws {
        let manager = HabitsManager(storage: InMemoryHabitDataStore(), currentDate: { .now })
        try await manager.enableSelectedHabits(["water"])
        let model = DailyHabitsViewModel(habitsFeature: manager, purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient()))
        await model.record(Habit(type: .water), value: 1)
        #expect(!model.isUnlocked)
        #expect(manager.entries.isEmpty)
    }

    @Test func unlockedTodayRecordsAndExposesSharedValues() async throws {
        let manager = HabitsManager(storage: InMemoryHabitDataStore(), currentDate: { .now })
        try await manager.enableSelectedHabits(["water"])
        let purchase = PurchaseManager(client: InMemoryPurchaseClient())
        await purchase.purchaseHabits()
        let model = DailyHabitsViewModel(habitsFeature: manager, purchaseFeature: purchase)
        let otherScreen = DailyHabitsViewModel(habitsFeature: manager, purchaseFeature: purchase)
        await model.record(Habit(type: .water), value: 1)
        #expect(model.feedback == 1)
        #expect(model.savingIDs.isEmpty)
        #expect(otherScreen.value(for: Habit(type: .water)) == 1)
    }

    @Test func failedValidationPreservesDraftAndDoesNotCelebrate() async throws {
        let manager = HabitsManager(storage: InMemoryHabitDataStore(), currentDate: { .now })
        try await manager.enableSelectedHabits(["exerciseSets"])
        let purchase = PurchaseManager(client: InMemoryPurchaseClient())
        await purchase.purchaseHabits()
        let model = DailyHabitsViewModel(habitsFeature: manager, purchaseFeature: purchase)
        model.drafts["exerciseSets"] = -3
        await model.record(Habit(type: .exerciseSets), value: -3)
        #expect(model.drafts["exerciseSets"] == -3)
        #expect(model.errorMessage != nil)
        #expect(model.feedback == 0)
        #expect(model.savingIDs.isEmpty)
    }

    @Test func labelsDistinguishMissingNoAndMood() {
        let model = DailyHabitsViewModel(habitsFeature: HabitsManager(storage: InMemoryHabitDataStore(), currentDate: { .now }), purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient()))
        #expect(model.description(for: Habit(type: .sauna), value: nil) == "Not recorded")
        #expect(model.description(for: Habit(type: .sauna), value: 0) == "No")
        #expect(model.description(for: Habit(type: .morningMood), value: 5) == "🤩 Energetic")
    }
}
