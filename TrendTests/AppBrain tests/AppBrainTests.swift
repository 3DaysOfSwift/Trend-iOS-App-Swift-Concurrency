// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct AppBrainTests {
    @Test func startupBeginsIndependentServicesBeforeWaitingForEither() async {
        let repository = StartupProbeRepository()
        let brain = TestAppBrainFactory.make(repository: repository)
        let startup = Task { @MainActor in await brain.start() }

        for _ in 0..<100 {
            if await repository.didStartBothOperations { break }
            await Task.yield()
        }
        let bothStartedBeforeRelease = await repository.didStartBothOperations
        await repository.releaseOperations()
        await startup.value

        #expect(bothStartedBeforeRelease)
    }

    @Test func goalWorkflowOwnsValidationAndUnitConversion() async throws {
        let repository = InMemoryWeightRepository()
        let brain = TestAppBrainFactory.make(repository: repository, unit: .pounds)

        #expect(!brain.settingsFeature.canSetGoal(from: "10"))
        #expect(brain.settingsFeature.canSetGoal(from: "154.3"))

        try await brain.settingsFeature.setGoal(from: "154.3")

        #expect(abs((brain.settingsFeature.goalWeightKilograms ?? 0) - 69.989) < 0.01)
    }

    @Test func settingsCommandsRemainBehindAppBrainBoundary() async {
        let repository = InMemoryWeightRepository(cloudStatus: .available)
        let brain = TestAppBrainFactory.make(repository: repository)

        brain.settingsFeature.setWeightUnit(.pounds)
        await brain.settingsFeature.refreshCloudStatus()

        #expect(brain.settingsFeature.selectedWeightUnit == .pounds)
        #expect(brain.settingsFeature.cloudSyncStatus == .available)
    }

    @Test func rejectsWeightEntriesDatedInTheFuture() async {
        let now = Date(timeIntervalSince1970: 1_000)
        let brain = TestAppBrainFactory.make(currentDate: { now })
        let draft = WeightEntryDraft(
            date: now.addingTimeInterval(1),
            value: "75"
        )

        await #expect(throws: WeightEntryManager.EntryDateError.futureDate) {
            try await brain.weightEntries.save(draft, editing: nil)
        }
        #expect(brain.weightEntries.entries.isEmpty)
    }

    @Test func savingEntryRefreshesProgress() async throws {
        let repository = InMemoryWeightRepository()
        let brain = TestAppBrainFactory.make(repository: repository)

        await brain.start()
        try await brain.weightEntries.save(WeightEntryDraft(value: "75"), editing: nil)

        #expect(brain.weightEntries.entries.count == 1)
        #expect(brain.progressFeature.progressSnapshot.points.count == 1)
    }
}

private actor StartupProbeRepository: WeightRepository, CloudSyncStatusProviding {
    private var loadStarted = false
    private var cloudStatusStarted = false
    private var loadContinuation: CheckedContinuation<Void, Never>?
    private var cloudStatusContinuation: CheckedContinuation<Void, Never>?

    var didStartBothOperations: Bool { loadStarted && cloudStatusStarted }

    func load() async throws -> WeightStore {
        loadStarted = true
        await withCheckedContinuation { loadContinuation = $0 }
        return WeightStore(entries: [], goalKilograms: nil)
    }

    func save(_ store: WeightStore) async throws {}

    func cloudStatus() async -> CloudSyncStatus {
        cloudStatusStarted = true
        await withCheckedContinuation { cloudStatusContinuation = $0 }
        return .available
    }

    func releaseOperations() {
        loadContinuation?.resume()
        loadContinuation = nil
        cloudStatusContinuation?.resume()
        cloudStatusContinuation = nil
    }
}
