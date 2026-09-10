// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitSynchronizationTests {
    private let date = Date(timeIntervalSince1970: 1_788_480_000)

    @Test func loadingSavedHabitsDoesNotContactCloudOrReloadReadyData() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let coffee = entry(.coffee, value: 2)
        let cache = FileHabitRepository(fileURL: file)
        try await cache.save(store([coffee]))
        let cloud = PausedHabitCloud(store: store([]))
        let manager = HabitsManager(repository: CloudKitHabitRepository(cache: cache, cloud: cloud), currentDate: { date })
        await manager.load()
        #expect(manager.entries == [coffee])
        #expect(await cloud.requestCount == 0)
        // Already loaded: displaying this data again must not read the file or contact iCloud.
        try FileManager.default.removeItem(at: file)
        await manager.load()
        #expect(manager.entries == [coffee])
        #expect(await cloud.requestCount == 0)
    }

    @Test func overlappingSynchronizationRequestsShareOneCloudCall() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cloud = PausedHabitCloud(store: store([]))
        let manager = HabitsManager(repository: CloudKitHabitRepository(
            cache: FileHabitRepository(fileURL: file), cloud: cloud), currentDate: { date })
        await manager.load()
        await cloud.pauseNextRequest()
        var started = 0
        var completed = 0
        let callers = (0..<4).map { _ in Task {
            started += 1
            await manager.synchronize()
            completed += 1
        } }
        await cloud.waitForPausedRequest()
        while started < 4 { await Task.yield() }
        #expect(completed == 0)
        callers[0].cancel()
        await cloud.releaseRequest()
        for caller in callers { await caller.value }
        #expect(completed == 4)
        #expect(await cloud.requestCount == 1)
    }

    @Test func localDataAndRecordingDoNotWaitForCloud() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cache = FileHabitRepository(fileURL: file)
        try await cache.save(store([]))
        let water = entry(.water, value: 2)
        let cloud = PausedHabitCloud(store: store([water]))
        await cloud.pauseNextRequest()
        let repository = CloudKitHabitRepository(cache: cache, cloud: cloud)
        let manager = HabitsManager(repository: repository, currentDate: { date })
        let refresh = Task { await manager.synchronize() }
        await cloud.waitForPausedRequest()
        #expect(manager.loadState == .ready)

        // This must finish while iCloud is still paused.
        let coffee = try await manager.recordCoffeeToday()
        #expect(coffee.value == 1)
        #expect(manager.todaysEntry(for: HabitTemplate.coffee.id) == coffee)
        #expect(await cloud.requestCount == 1)
        await cloud.releaseRequest()
        await refresh.value

        #expect(manager.entries.count == 2 && manager.entries.contains(water) && manager.entries.contains(coffee))
        #expect(try await cache.load().entries.count == 2)
        #expect(await cloud.currentStore.entries == manager.entries)
        #expect(await cloud.requestCount == 2)
    }

    @Test func cloudFailureDoesNotTurnASavedEntryIntoAFailedSave() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cache = FileHabitRepository(fileURL: file)
        try await cache.save(store([]))
        let cloud = PausedHabitCloud(store: store([]))
        await cloud.setFailure(true)
        let manager = HabitsManager(repository: CloudKitHabitRepository(cache: cache, cloud: cloud), currentDate: { date })
        await manager.synchronize()
        let coffee = try await manager.recordCoffeeToday()
        #expect(manager.loadState == .ready)
        #expect(try await cache.load().entries == [coffee])
        await manager.synchronize()
        #expect(manager.synchronizationError != nil)
        #expect(manager.entries == [coffee])

        await cloud.setFailure(false)
        await manager.synchronize()
        #expect(manager.synchronizationError == nil)
        #expect(await cloud.currentStore.entries == [coffee])
    }

    @Test func savingAnOlderManagerCopyPreservesDownloadedEntries() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cache = FileHabitRepository(fileURL: file)
        let previous = store([])
        try await cache.save(previous)
        let water = entry(.water, value: 2)
        try await cache.acceptSynchronizedStore(store([water]), localAtStart: previous)
        let coffee = entry(.coffee, value: 1)
        let saved = try await cache.save(store([coffee]), replacing: previous)
        #expect(saved.entries.count == 2)
        #expect(saved.entries.contains(water))
        #expect(saved.entries.contains(coffee))
    }

    @Test func lastSynchronizedHistorySurvivesRestartAndPreservesDeletions() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cache = FileHabitRepository(fileURL: file)
        let coffee = entry(.coffee, value: 1)
        let initial = store([coffee])
        try await cache.save(initial)
        try await cache.acceptSynchronizedStore(initial, localAtStart: initial)
        try await cache.save(store([]))

        let reopened = FileHabitRepository(fileURL: file)
        let document = try await reopened.readDocument()
        #expect(document.store.entries.isEmpty)
        #expect(document.lastSynchronizedStore == initial)
        let water = entry(.water, value: 3)
        let cloud = PausedHabitCloud(store: store([coffee, water]))
        let repository = CloudKitHabitRepository(cache: reopened, cloud: cloud)
        try await repository.synchronize()
        #expect(try await reopened.load().entries == [water])
        #expect(await cloud.currentStore.entries == [water])
    }

    @Test func deletionDuringUploadRemainsPendingAfterTheUploadFinishes() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cache = FileHabitRepository(fileURL: file)
        let coffee = entry(.coffee, value: 1)
        let atStart = store([coffee])
        try await cache.save(atStart)
        try await cache.save(store([]))
        try await cache.acceptSynchronizedStore(atStart, localAtStart: atStart)
        let document = try await cache.readDocument()
        #expect(document.store.entries.isEmpty)
        #expect(document.lastSynchronizedStore == atStart)
        let cloud = PausedHabitCloud(store: atStart)
        try await CloudKitHabitRepository(cache: cache, cloud: cloud).synchronize()
        #expect(await cloud.currentStore.entries.isEmpty)
    }

    @Test func differentDaysAndRemoteDeletionArePreserved() async throws {
        let merge = HabitStoreChanges(calendar: .current)
        let yesterday = entry(.coffee, value: 2, on: date.addingTimeInterval(-86_400))
        let today = entry(.coffee, value: 3)
        let water = entry(.water, value: 4)
        let result = merge.apply(from: store([yesterday]), to: store([yesterday, today]), onto: store([water]))
        #expect(result.entries.count == 2)
        #expect(result.entries.contains(today))
        #expect(result.entries.contains(water))
        #expect(!result.entries.contains(yesterday))
    }

    @Test func pendingLocalEditWinsWhenBothDevicesEditTheSameDay() async throws {
        let merge = HabitStoreChanges(calendar: .current)
        let original = entry(.coffee, value: 1)
        let local = entry(.coffee, value: 2)
        let remote = entry(.coffee, value: 3)
        let result = merge.apply(from: store([original]), to: store([local]), onto: store([remote]))
        #expect(result.entries == [local])
    }

    @Test func independentHabitSelectionsAreMerged() async throws {
        let merge = HabitStoreChanges(calendar: .current)
        let before = HabitStore(selectedHabitIDs: [HabitTemplate.coffee.id], entries: [])
        let local = HabitStore(selectedHabitIDs: [HabitTemplate.water.id], entries: [])
        let remote = HabitStore(selectedHabitIDs: [HabitTemplate.coffee.id, HabitTemplate.sleep.id], entries: [])
        let result = merge.apply(from: before, to: local, onto: remote)
        #expect(Set(result.selectedHabitIDs) == Set([HabitTemplate.water.id, HabitTemplate.sleep.id]))
    }

    @Test func failingLocalWriteDoesNotPublishAnUnsavedEntry() async throws {
        let file = temporaryFile()
        let directory = file.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let cache = FileHabitRepository(fileURL: file)
        try await cache.save(store([]))
        let manager = HabitsManager(repository: cache, currentDate: { date })
        await manager.load()
        // Replace the destination with a directory, so a file write must fail.
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        do {
            try await manager.recordCoffeeToday()
            #expect(false)
        } catch {}
        #expect(manager.entries.isEmpty)
    }

    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "habits.json")
    }

    private func entry(_ habit: HabitTemplate, value: Double, on day: Date? = nil) -> HabitEntry {
        HabitEntry(id: UUID(), habitID: habit.id, date: day ?? date, value: value)
    }

    private func store(_ entries: [HabitEntry]) -> HabitStore {
        HabitStore(selectedHabitIDs: [HabitTemplate.coffee.id, HabitTemplate.water.id], entries: entries)
    }
}

private actor PausedHabitCloud: HabitCloudClient {
    private(set) var currentStore: HabitStore
    private(set) var requestCount = 0
    private var shouldPause = false
    private var shouldFail = false
    private var paused: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?

    init(store: HabitStore) { currentStore = store }

    func merge(_ local: HabitStore, since previous: HabitStore?) async throws -> HabitStore {
        requestCount += 1
        if shouldPause {
            shouldPause = false
            await withCheckedContinuation { continuation in
                paused = continuation
                started?.resume()
                started = nil
            }
        }
        if shouldFail { throw CocoaError(.fileReadUnknown) }
        currentStore = HabitStoreChanges(calendar: .current).apply(
            from: previous ?? HabitStore(selectedHabitIDs: [], entries: []), to: local, onto: currentStore)
        return currentStore
    }

    func setFailure(_ value: Bool) { shouldFail = value }
    func pauseNextRequest() { shouldPause = true }
    func waitForPausedRequest() async {
        if paused != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func releaseRequest() { paused?.resume(); paused = nil }
}
