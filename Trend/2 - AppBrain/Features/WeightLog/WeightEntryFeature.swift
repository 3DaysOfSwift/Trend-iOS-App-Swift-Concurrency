// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

@MainActor
protocol TodayFeature: AnyObject {
    var weightLogState: WeightLogState { get }
    var latestWeightEntry: WeightEntry? { get }
    var latestWeightChangeKilograms: Double? { get }
    var progressSnapshot: ProgressSnapshot { get }
    var goalWeightKilograms: Double? { get }
    var dailyStreakSnapshot: DailyStreakSnapshot { get }
    var selectedWeightUnit: WeightUnit { get }
    var latestPermittedEntryDate: Date { get }

    func makeWeightEntryDraft(editing entry: WeightEntry?) -> WeightEntryDraft
    func checkIn(_ draft: WeightEntryDraft) async throws -> DailyCheckInResult
    func refresh() async
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

/// The complete weight-entry capability retained by AppBrain. Each ViewModel
/// depends on the narrower protocol that describes only what its screen needs.
@MainActor
protocol WeightEntryFeature: TodayFeature, WeightEntryEditorFeature, HistoryFeature {}
