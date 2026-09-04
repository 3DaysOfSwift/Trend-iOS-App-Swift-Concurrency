import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private let today: any TodayFeature

    var draft: WeightEntryDraft
    var errorMessage: String?
    private(set) var isSaving = false
    private(set) var submittedResult: DailyCheckInResult?

    init(today: any TodayFeature = AppBrain.shared.weightEntries) {
        self.today = today
        draft = today.makeWeightEntryDraft(editing: nil)
    }

    var latestEntry: WeightEntry? { today.latestWeightEntry }
    var changeKilograms: Double? { today.latestWeightChangeKilograms }
    var progressSnapshot: ProgressSnapshot { today.progressSnapshot }
    var streakSnapshot: DailyStreakSnapshot { today.dailyStreakSnapshot }
    var unit: WeightUnit { today.selectedWeightUnit }
    var latestPermittedEntryDate: Date { today.latestPermittedEntryDate }
    var canSave: Bool { !draft.value.isEmpty && !isSaving }

    func save() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        do {
            submittedResult = try await today.checkIn(draft)
            draft = today.makeWeightEntryDraft(editing: nil)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func beginAnotherCheckIn() {
        submittedResult = nil
        errorMessage = nil
    }
}
