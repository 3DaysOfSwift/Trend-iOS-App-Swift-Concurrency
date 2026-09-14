// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private let today: WeightEntryManager
    private var hasPreparedInput = false
    private var inputUnit: WeightUnit

    var draft: WeightEntryDraft
    var errorMessage: String?
    private(set) var isSaving = false
    private(set) var submittedResult: DailyCheckInResult?

    init(today: WeightEntryManager = AppModel.shared.weightEntries) {
        self.today = today
        draft = today.makeDailyWeightDraft()
        inputUnit = today.selectedWeightUnit
        hasPreparedInput = today.weightLogState == .ready
    }

    var latestEntry: WeightEntry? { today.latestWeightEntry }
    var showsHabits: Bool { today.weightLogState == .ready && today.hasRecordedWeightToday }
    var loadState: WeightLogState { today.weightLogState }
    var changeKilograms: Double? { today.latestWeightChangeKilograms }
    var progressSnapshot: WeightHistoryData { today.progressSnapshot }
    var goalKilograms: Double? { today.goalWeightKilograms }
    var streakSnapshot: DailyStreakSnapshot { today.dailyStreakSnapshot }
    var unit: WeightUnit { today.selectedWeightUnit }
    var inputStyle: WeightInputStyle { today.weightInputStyle }
    func useKeyboard() { today.setWeightInputStyle(.keyboard) }

    func prepareWeightInput() {
        guard loadState == .ready, !hasPreparedInput else { return }
        if draft.value.isEmpty {
            draft.value = today.makeDailyWeightDraft().value
        }
        hasPreparedInput = true
    }

    func updateInputUnit() {
        guard inputUnit != unit else { return }
        draft.value = today.convertWeightInput(draft.value, from: inputUnit)
        inputUnit = unit
    }
    var latestPermittedEntryDate: Date { today.latestPermittedEntryDate }
    var canSave: Bool { loadState == .ready && !draft.value.isEmpty && !isSaving }

    func refresh() async {
        await today.refresh()
    }

    func save() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        do {
            submittedResult = try await today.checkIn(draft)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func beginAnotherCheckIn() {
        draft = today.makeDailyWeightDraft()
        inputUnit = unit
        hasPreparedInput = loadState == .ready
        submittedResult = nil
        errorMessage = nil
    }
}
