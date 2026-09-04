import Foundation
import Observation

@MainActor
@Observable
final class ProgressTracker {
    private let insights: ProgressInsights
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    private(set) var snapshot: ProgressSnapshot = .empty
    private(set) var isLoading = false
    private(set) var range: ProgressRange = .threeMonths

    init(insights: ProgressInsights = ProgressInsights()) { self.insights = insights }

    func refresh(entries: [WeightEntry], goalKilograms: Double? = nil) async {
        isLoading = true
        snapshot = await insights.prepare(entries: entries, range: range, goalKilograms: goalKilograms)
        isLoading = false
    }

    func select(_ range: ProgressRange, entries: [WeightEntry], goalKilograms: Double? = nil) {
        self.range = range
        isLoading = true
        refreshTask?.cancel()
        refreshTask = Task { [insights] in
            await Task.yield()
            guard !Task.isCancelled else { return }
            let prepared = await insights.prepare(entries: entries, range: range, goalKilograms: goalKilograms)
            guard !Task.isCancelled else { return }
            snapshot = prepared
            isLoading = false
        }
    }
}
