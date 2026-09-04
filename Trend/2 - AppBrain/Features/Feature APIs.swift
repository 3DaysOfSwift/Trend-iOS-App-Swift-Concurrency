// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

/// The narrow application capabilities retained by ViewModels.
///
/// These protocols describe what each part of the application can do without
/// exposing which managers, repositories, or workflows implement that behavior.

@MainActor
protocol TodayFeature: AnyObject {
    var latestWeightEntry: WeightEntry? { get }
    var latestWeightChangeKilograms: Double? { get }
    var progressSnapshot: ProgressSnapshot { get }
    var goalWeightKilograms: Double? { get }
    var dailyStreakSnapshot: DailyStreakSnapshot { get }
    var selectedWeightUnit: WeightUnit { get }
    var latestPermittedEntryDate: Date { get }

    func makeWeightEntryDraft(editing entry: WeightEntry?) -> WeightEntryDraft
    func checkIn(_ draft: WeightEntryDraft) async throws -> DailyCheckInResult
}

@MainActor
protocol WeightEntryEditorFeature: AnyObject {
    var selectedWeightUnit: WeightUnit { get }
    var latestPermittedEntryDate: Date { get }

    func makeWeightEntryDraft(editing entry: WeightEntry?) -> WeightEntryDraft
    func save(_ draft: WeightEntryDraft, editing entry: WeightEntry?) async throws
}

@MainActor
protocol HistoryFeature: AnyObject {
    var weightLogState: WeightLogState { get }
    var entries: [WeightEntry] { get }
    var selectedWeightUnit: WeightUnit { get }

    func delete(_ entry: WeightEntry) async throws
    func refresh() async
}

/// The complete weight-entry capability. Individual ViewModels may depend on a
/// narrower parent protocol, while AppBrain stores one coherent implementation.
@MainActor
protocol WeightEntryFeature: TodayFeature, WeightEntryEditorFeature, HistoryFeature {}

@MainActor
protocol ProgressFeature: AnyObject {
    var progressSnapshot: ProgressSnapshot { get }
    var goalWeightKilograms: Double? { get }
    var selectedWeightUnit: WeightUnit { get }
    var isPreparingProgress: Bool { get }
    var selectedProgressRange: ProgressRange { get }

    func selectProgressRange(_ range: ProgressRange)
}

@MainActor
protocol SettingsFeature: AnyObject {
    var selectedWeightUnit: WeightUnit { get }
    var cloudSyncStatus: CloudSyncStatus { get }
    var goalWeightKilograms: Double? { get }

    func setWeightUnit(_ unit: WeightUnit)
    func refreshCloudStatus() async
    func canSetGoal(from text: String) -> Bool
    func setGoal(from text: String) async throws
    func exportData() async throws -> Data
    func importData(from url: URL) async throws
    func deleteAllData() async throws
}

@MainActor
protocol HabitsFeature: AnyObject {
    var habits: [Habit] { get }
    var entries: [HabitEntry] { get }
    var errorMessage: String? { get }

    func refresh() async
    func selectTemplates(_ templateIDs: Set<String>) async throws
    func record(_ value: Double, for habitID: String, on date: Date) async throws
    func entry(for habitID: String, on date: Date) -> HabitEntry?
}

@MainActor
protocol PurchaseFeature: AnyObject {
    var habitsProduct: PurchaseProduct? { get }
    var hasUnlockedHabits: Bool { get }
    var isLoading: Bool { get }
    var isPurchasing: Bool { get }
    var message: String? { get }

    func start() async
    func purchaseHabits() async
    func restorePurchases() async
    func dismissMessage()
}
