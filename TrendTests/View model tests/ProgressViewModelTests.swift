// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct ProgressViewModelTests {
    @Test func exposesSnapshotGoalUnitAndLoadingState() async {
        let now = Date()
        let entries = [
            WeightEntry(date: now.addingTimeInterval(-86_400), kilograms: 82),
            WeightEntry(date: now, kilograms: 80)
        ]
        let repository = InMemoryWeightRepository(store: .init(entries: entries, goalKilograms: 75))
        let brain = TestAppBrainFactory.make(repository: repository, unit: .pounds)
        await brain.applicationDidFinishLaunching()
        let viewModel = ProgressViewModel(progress: brain.progressFeature)

        #expect(viewModel.snapshot.points.map(\.kilograms) == [82, 80])
        #expect(viewModel.snapshot.changeKilograms == -2)
        #expect(viewModel.goalKilograms == 75)
        #expect(viewModel.unit == .pounds)
        #expect(!viewModel.isLoading)
    }

    @Test func changingRangeDelegatesToProgressFeature() async {
        let brain = TestAppBrainFactory.make()
        let viewModel = ProgressViewModel(progress: brain.progressFeature)

        viewModel.range = .all
        let timeout = ContinuousClock.now.advanced(by: .seconds(1))
        while viewModel.isLoading, ContinuousClock.now < timeout {
            try? await Task.sleep(for: .milliseconds(1))
        }

        #expect(viewModel.range == .all)
        #expect(!viewModel.isLoading)
    }
}
