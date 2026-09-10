// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation
import Testing
import os
@testable import Trend

@MainActor
struct HabitsWorkerIntegrationTests {
    @Test func overlappingLoadsShareOneLoadEvenIfACallerCancels() async {
        await checkSharedLoad(failing: false)
    }

    @Test func overlappingLoadsShareFailureAndAllowAnotherLoad() async {
        await checkSharedLoad(failing: true)
    }

    private func checkSharedLoad(failing: Bool) async {
        let repository = SuspendedHabitRepository()
        let manager = HabitsManager(repository: repository, currentDate: TestAppModelFactory.currentDate)
        await repository.pauseNextLoad()
        var started = 0
        var finished = 0
        let callers = (0..<4).map { _ in
            Task {
                started += 1
                await manager.load()
                if failing {
                    #expect(manager.errorMessage != nil)
                } else {
                    #expect(manager.loadState == .ready)
                }
                finished += 1
            }
        }
        await repository.waitForPausedLoad()
        while started < 4 { await Task.yield() }
        #expect(finished == 0)
        #expect(await repository.loadCount == 1)
        callers[0].cancel()
        await repository.releaseLoad(failing: failing)
        for caller in callers { await caller.value }
        #expect(finished == 4)
        #expect(await repository.loadCount == 1)

        await manager.load()
        #expect(await repository.loadCount == (failing ? 2 : 1))
        #expect(manager.loadState == .ready)
        #expect(manager.errorMessage == nil)
    }

    @Test func overlappingRecordingsPreserveBothValues() async throws {
        let repository = SuspendedHabitRepository()
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: repository, currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        await repository.pauseNextSave()
        let first = Task { try await manager.recordCoffeeToday() }
        await repository.waitForPausedSave()
        let second = Task { try await manager.recordCoffeeToday() }
        #expect(manager.entries.isEmpty)
        await repository.releaseSave()
        let firstEntry = try await first.value
        let secondEntry = try await second.value
        #expect(firstEntry.value == 1)
        #expect(secondEntry.value == 2)
        #expect(firstEntry.id != secondEntry.id)
        #expect(manager.todaysEntry(for: HabitTemplate.coffee.id) == secondEntry)
        #expect(manager.todaysEntry(for: HabitTemplate.coffee.id)?.value == 2)
        #expect(manager.currentWeekSummary(for: HabitTemplate.coffee.id).totalValue == 2)
        let saved = try await repository.load()
        #expect(saved.entries.first?.value == 2)
    }

    @Test func loadingAfterARecordingKeepsTheSavedData() async throws {
        let repository = SuspendedHabitRepository()
        let manager = HabitsManager(repository: repository, currentDate: TestAppModelFactory.currentDate)
        try await manager.selectTemplates([HabitTemplate.water.id])
        await repository.pauseNextSave()
        let recording = Task { try await manager.recordGlassOfWaterToday() }
        await repository.waitForPausedSave()
        let refresh = Task { await manager.load() }
        await repository.releaseSave()
        try await recording.value
        await refresh.value
        #expect(manager.entries.first?.value == 1)
        #expect(manager.loadState == .ready)
    }

    @Test func failedSavePreservesPublishedValuesAndAllowsTheNextOperation() async throws {
        let repository = SuspendedHabitRepository()
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: repository, currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.recordCoffeeToday()
        await repository.pauseNextSave()
        let failed = Task { try await manager.recordCoffeeToday() }
        await repository.waitForPausedSave()
        await repository.releaseSave(failing: true)
        do {
            try await failed.value
            #expect(false)
        } catch {}
        #expect(manager.todaysEntry(for: HabitTemplate.coffee.id)?.value == 1)
        #expect(manager.currentWeekSummary(for: HabitTemplate.coffee.id).totalValue == 1)
        try await manager.recordCoffeeToday()
        #expect(manager.todaysEntry(for: HabitTemplate.coffee.id)?.value == 2)
    }

    @Test func cancelledQueuedRecordingDoesNotWrite() async throws {
        let repository = SuspendedHabitRepository()
        let manager = HabitsManager(repository: repository, currentDate: TestAppModelFactory.currentDate)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        await repository.pauseNextSave()
        let first = Task { try await manager.recordCoffeeToday() }
        await repository.waitForPausedSave()
        let cancelled = Task { try await manager.recordCoffeeToday() }
        cancelled.cancel()
        await repository.releaseSave()
        try await first.value
        do {
            try await cancelled.value
            #expect(false)
        } catch {}
        #expect(manager.entries.first?.value == 1)
    }

    @Test func changingDayRecalculatesSummariesWithoutLoadingStorage() async throws {
        let repository = SuspendedHabitRepository()
        var date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: repository, currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.recordCoffeeToday()
        date = date.addingTimeInterval(2 * 86_400)
        await manager.updateCurrentDay()
        #expect(manager.todaysEntry(for: HabitTemplate.coffee.id) == nil)
        #expect(manager.currentWeekSummary(for: HabitTemplate.coffee.id).currentStreak == 0)
        #expect(await repository.loadCount == 0)
    }

    @Test func loadingPublishesPreparedSummaries() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let store = HabitStore(selectedHabitIDs: [HabitTemplate.coffee.id], entries: [
            HabitEntry(id: UUID(), habitID: HabitTemplate.coffee.id, date: date, value: 3)
        ])
        let manager = HabitsManager(repository: InMemoryHabitRepository(store: store), currentDate: { date })
        await manager.load()
        #expect(manager.loadState == .ready)
        #expect(manager.todaysEntry(for: HabitTemplate.coffee.id)?.value == 3)
        #expect(manager.currentWeekSummary(for: HabitTemplate.coffee.id).totalValue == 3)
        #expect(manager.lifetimeSummary(for: HabitTemplate.coffee.id).totalValue == 3)
    }

    @Test func successfulSaveStillPublishesWhenCancellationArrivesDuringPersistence() async throws {
        let repository = SuspendedHabitRepository()
        let manager = HabitsManager(repository: repository, currentDate: TestAppModelFactory.currentDate)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        await repository.pauseNextSave()
        let recording = Task { try await manager.recordCoffeeToday() }
        await repository.waitForPausedSave()
        recording.cancel()
        await repository.releaseSave()
        try await recording.value
        #expect(manager.entries.first?.value == 1)
        let saved = try await repository.load()
        #expect(saved.entries == manager.entries)
    }

    @Test func swiftUIObservationTracksSharedFeatureState() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: InMemoryHabitRepository(), currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        let viewModel = CoffeeTrackingViewModel(habitsFeature: manager)
        let changed = OSAllocatedUnfairLock(initialState: false)
        withObservationTracking {
            _ = viewModel.weekSummary
        } onChange: {
            changed.withLock { $0 = true }
        }
        try await manager.recordCoffeeToday()
        #expect(changed.withLock { $0 })
        #expect(viewModel.weekSummary.currentStreak == 1)
        #expect(viewModel.weeklyTotal == 1)
    }
}

private actor SuspendedHabitRepository: HabitRepository {
    private var store = HabitStore(selectedHabitIDs: [], entries: [])
    private var pauseLoad = false
    private var loadRelease: CheckedContinuation<Void, Never>?
    private var loadStarted: CheckedContinuation<Void, Never>?
    private var failLoad = false
    private var pauseSave = false
    private var saveRelease: CheckedContinuation<Void, Never>?
    private var saveStarted: CheckedContinuation<Void, Never>?
    private var failSave = false
    private(set) var loadCount = 0

    func load() async throws -> HabitStore {
        loadCount += 1
        if pauseLoad {
            pauseLoad = false
            await withCheckedContinuation { continuation in
                loadRelease = continuation
                loadStarted?.resume()
                loadStarted = nil
            }
            if failLoad {
                failLoad = false
                throw CocoaError(.fileReadUnknown)
            }
        }
        return store
    }

    func save(_ store: HabitStore) async throws {
        if pauseSave {
            pauseSave = false
            await withCheckedContinuation { continuation in
                saveRelease = continuation
                saveStarted?.resume()
                saveStarted = nil
            }
            if failSave {
                failSave = false
                throw CocoaError(.fileWriteUnknown)
            }
        }
        self.store = store
    }

    func pauseNextLoad() { pauseLoad = true }

    func waitForPausedLoad() async {
        if loadRelease != nil { return }
        await withCheckedContinuation { loadStarted = $0 }
    }

    func releaseLoad(failing: Bool = false) {
        failLoad = failing
        loadRelease?.resume()
        loadRelease = nil
    }

    func pauseNextSave() { pauseSave = true }

    func waitForPausedSave() async {
        if saveRelease != nil { return }
        await withCheckedContinuation { saveStarted = $0 }
    }

    func releaseSave(failing: Bool = false) {
        failSave = failing
        saveRelease?.resume()
        saveRelease = nil
    }
}
