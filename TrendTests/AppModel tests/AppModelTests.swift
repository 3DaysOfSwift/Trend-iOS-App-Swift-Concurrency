// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct AppModelTests {
    @Test func applicationLaunchBeginsIndependentServicesBeforeWaitingForEither() async {
        let repository = StartupProbeRepository()
        let appModel = TestAppModelFactory.make(repository: repository)
        let applicationLaunch = Task { @MainActor in
            await appModel.applicationDidFinishLaunching()
        }

        for _ in 0..<100 {
            if await repository.didStartBothOperations { break }
            await Task.yield()
        }
        let bothStartedBeforeRelease = await repository.didStartBothOperations
        await repository.releaseOperations()
        await applicationLaunch.value

        #expect(bothStartedBeforeRelease)
    }

    @Test func simultaneousScenesAwaitTheSameApplicationLaunchWork() async {
        let repository = StartupProbeRepository()
        let appModel = TestAppModelFactory.make(repository: repository)
        let completion = CompletionProbe()
        let firstScene = Task { @MainActor in
            await appModel.applicationDidFinishLaunching()
        }

        for _ in 0..<100 {
            if await repository.didStartBothOperations { break }
            await Task.yield()
        }
        let secondScene = Task { @MainActor in
            await appModel.applicationDidFinishLaunching()
            await completion.markCompleted()
        }
        for _ in 0..<10 { await Task.yield() }

        #expect(!(await completion.isCompleted))

        await repository.releaseOperations()
        await firstScene.value
        await secondScene.value

        #expect(await completion.isCompleted)
    }

    @Test func goalWorkflowOwnsValidationAndUnitConversion() async throws {
        let repository = InMemoryWeightRepository()
        let appModel = TestAppModelFactory.make(repository: repository, unit: .pounds)

        #expect(!appModel.settingsFeature.canSetGoal(from: "10"))
        #expect(appModel.settingsFeature.canSetGoal(from: "154.3"))

        try await appModel.settingsFeature.setGoal(from: "154.3")

        #expect(abs((appModel.settingsFeature.goalWeightKilograms ?? 0) - 69.989) < 0.01)
    }

    @Test func settingsCommandsRemainBehindAppModelBoundary() async {
        let repository = InMemoryWeightRepository(cloudStatus: .available)
        let appModel = TestAppModelFactory.make(repository: repository)

        appModel.settingsFeature.setWeightUnit(.pounds)
        await appModel.settingsFeature.refreshCloudStatus()

        #expect(appModel.settingsFeature.selectedWeightUnit == .pounds)
        #expect(appModel.settingsFeature.cloudSyncStatus == .available)
    }

    @Test func rejectsWeightEntriesDatedInTheFuture() async {
        let now = Date(timeIntervalSince1970: 1_000)
        let appModel = TestAppModelFactory.make(currentDate: { now })
        let draft = WeightEntryDraft(
            date: now.addingTimeInterval(1),
            value: "75"
        )

        await #expect(throws: WeightEntryManager.EntryDateError.futureDate) {
            try await appModel.weightEntries.save(draft, editing: nil)
        }
        #expect(appModel.weightEntries.entries.isEmpty)
    }

    @Test func savingEntryRefreshesProgress() async throws {
        let repository = InMemoryWeightRepository()
        let appModel = TestAppModelFactory.make(repository: repository)

        await appModel.applicationDidFinishLaunching()
        try await appModel.weightEntries.save(WeightEntryDraft(value: "75"), editing: nil)

        #expect(appModel.weightEntries.entries.count == 1)
        #expect(appModel.progressFeature.progressSnapshot.points.count == 1)
    }
}

private actor CompletionProbe {
    private(set) var isCompleted = false

    func markCompleted() {
        isCompleted = true
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
