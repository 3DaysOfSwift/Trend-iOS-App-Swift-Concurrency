import Foundation
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    private let history: any HistoryFeature
    var errorMessage: String?

    init(history: any HistoryFeature = AppBrain.shared.weightEntries) {
        self.history = history
    }

    var state: WeightLogState { history.weightLogState }
    var entries: [WeightEntry] { history.entries }
    var unit: WeightUnit { history.selectedWeightUnit }

    func delete(_ entry: WeightEntry) async {
        do { try await history.delete(entry) }
        catch { errorMessage = error.localizedDescription }
    }

    func refresh() async { await history.refresh() }
}
