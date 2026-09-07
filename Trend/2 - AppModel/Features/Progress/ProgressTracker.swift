// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

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
        refreshTask?.cancel()
        isLoading = true
        let task = makeRefreshTask(entries: entries, goalKilograms: goalKilograms)
        refreshTask = task
        await task.value
    }

    func select(_ range: ProgressRange, entries: [WeightEntry], goalKilograms: Double? = nil) {
        self.range = range
        isLoading = true
        refreshTask?.cancel()
        refreshTask = makeRefreshTask(entries: entries, goalKilograms: goalKilograms)
    }

    private func makeRefreshTask(
        entries: [WeightEntry],
        goalKilograms: Double?
    ) -> Task<Void, Never> {
        let selectedRange = range
        return Task { [insights] in
            await Task.yield()
            guard !Task.isCancelled else { return }
            let prepared = await insights.prepare(
                entries: entries,
                range: selectedRange,
                goalKilograms: goalKilograms
            )
            guard !Task.isCancelled else { return }
            snapshot = prepared
            isLoading = false
        }
    }
}
