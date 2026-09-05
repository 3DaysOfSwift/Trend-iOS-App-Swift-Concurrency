// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitsViewModel {
    private let habitsFeature: any HabitsFeature
    private let purchaseFeature: any PurchaseFeature
    private let currentDate: () -> Date

    var isChoosingHabits = false

    init(
        habitsFeature: any HabitsFeature = AppBrain.shared.habitsFeature,
        purchaseFeature: any PurchaseFeature = AppBrain.shared.purchaseFeature,
        currentDate: @escaping () -> Date = { .now }
    ) {
        self.habitsFeature = habitsFeature
        self.purchaseFeature = purchaseFeature
        self.currentDate = currentDate
    }

    var habits: [Habit] { habitsFeature.habits }
    var hasUnlockedHabits: Bool { purchaseFeature.hasUnlockedHabits }
    var isLoadingPurchase: Bool { purchaseFeature.isLoading }
    var isPurchasing: Bool { purchaseFeature.isPurchasing }
    var purchaseMessage: String? { purchaseFeature.message }
    var productName: String { purchaseFeature.habitsProduct?.displayName ?? "Trend Habits" }
    var productDescription: String {
        purchaseFeature.habitsProduct?.description
            ?? "Track the daily signals that matter to you and reveal their direction over time."
    }
    var productPrice: String { purchaseFeature.habitsProduct?.displayPrice ?? "One-time purchase" }

    func purchaseHabits() async -> Bool {
        let wasAlreadyUnlocked = purchaseFeature.hasUnlockedHabits
        await purchaseFeature.purchaseHabits()
        return !wasAlreadyUnlocked && purchaseFeature.hasUnlockedHabits
    }
    func restorePurchases() async { await purchaseFeature.restorePurchases() }
    func dismissPurchaseMessage() { purchaseFeature.dismissMessage() }

    func hasCheckedIn(_ habit: Habit) -> Bool {
        habitsFeature.entry(for: habit.id, on: currentDate()) != nil
    }

    func todaySummary(for habit: Habit) -> String {
        guard let entry = habitsFeature.entry(for: habit.id, on: currentDate()) else {
            return "Ready to check in"
        }
        switch habit.valueType {
        case .timeOfDay:
            let hour = Int(entry.value) / 60
            let minute = Int(entry.value) % 60
            let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: currentDate()) ?? currentDate()
            return "Today · \(date.formatted(date: .omitted, time: .shortened))"
        case .rating:
            return "Today · \(Int(entry.value)) of 5"
        case .number:
            let value = entry.value.formatted(.number.precision(.fractionLength(0...1)))
            return "Today · \(value) \(habit.unit)"
        }
    }
}
