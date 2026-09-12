// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitSynchronizationTests {
    private let date = Date(timeIntervalSince1970: 1_788_480_000)

    @Test func savedHabitsContainOnlyIDsAndDecodeIntoHabits() throws {
        let original = HabitData(enabledHabits: [Habit(type: .coffee), Habit(type: .runningDistance)], entries: [])
        var calculated = original
        calculated.summaryDate = date
        calculated.weekSummaries = ["coffee": HabitWeekSummary(currentStreak: 2, days: [])]
        calculated.lifetimeSummaries = ["coffee": HabitLifetimeSummary(totalValue: 3, firstEntryDate: date)]
        let coffee = entry(.coffee, value: 3)
        calculated.todayEntries = ["coffee": coffee]
        calculated.entriesByDay = ["coffee": [date: coffee]]
        let encoded = try JSONEncoder().encode(calculated)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(json["enabledHabitIDs"] as? [String] == ["coffee", "runningDistance"])
        #expect(Set(json.keys) == ["enabledHabitIDs", "entries"])
        #expect(try JSONDecoder().decode(HabitData.self, from: encoded) == original)
    }

    @Test func loadingSavedHabitsDoesNotContactCloudOrReloadReadyData() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let coffee = entry(.coffee, value: 2)
        let cache = FileHabitDataStore(fileURL: file)
        try await cache.seed(data([coffee]))
        let cloud = PausedHabitCloud(data: data([]))
        let manager = HabitsManager(storage: CloudKitHabitDataStore(cache: cache, cloud: cloud), currentDate: { date })
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
        let cloud = PausedHabitCloud(data: data([]))
        let manager = HabitsManager(storage: CloudKitHabitDataStore(
            cache: FileHabitDataStore(fileURL: file), cloud: cloud), currentDate: { date })
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
        let cache = FileHabitDataStore(fileURL: file)
        try await cache.seed(data([]))
        let water = entry(.water, value: 2)
        let cloud = PausedHabitCloud(data: data([water]))
        await cloud.pauseNextRequest()
        let dataStore = CloudKitHabitDataStore(cache: cache, cloud: cloud)
        let manager = HabitsManager(storage: dataStore, currentDate: { date })
        let refresh = Task { await manager.synchronize() }
        await cloud.waitForPausedRequest()
        #expect(manager.loadState == .ready)

        // This must finish while iCloud is still paused.
        let coffee = try await manager.recordCoffee()
        #expect(coffee.value == 1)
        #expect(manager.todaysEntry(for: Habit(type: .coffee).id) == coffee)
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
        let cache = FileHabitDataStore(fileURL: file)
        try await cache.seed(data([]))
        let cloud = PausedHabitCloud(data: data([]))
        await cloud.setFailure(true)
        let manager = HabitsManager(storage: CloudKitHabitDataStore(cache: cache, cloud: cloud), currentDate: { date })
        await manager.synchronize()
        let coffee = try await manager.recordCoffee()
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
        let cache = FileHabitDataStore(fileURL: file)
        let previous = data([])
        try await cache.seed(previous)
        let water = entry(.water, value: 2)
        try await cache.acceptSynchronizedData(data([water]), localAtStart: previous)
        let coffee = entry(.coffee, value: 1)
        let saved = try await cache.save(data([coffee]), replacing: previous)
        #expect(saved.entries.count == 2)
        #expect(saved.entries.contains(water))
        #expect(saved.entries.contains(coffee))
    }

    @Test func lastSynchronizedHistorySurvivesRestartAndPreservesDeletions() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cache = FileHabitDataStore(fileURL: file)
        let coffee = entry(.coffee, value: 1)
        let initial = data([coffee])
        try await cache.seed(initial)
        try await cache.acceptSynchronizedData(initial, localAtStart: initial)
        try await cache.seed(data([]))

        let reopened = FileHabitDataStore(fileURL: file)
        let document = try await reopened.readDocument()
        #expect(document.data.entries.isEmpty)
        #expect(document.lastSynchronizedData == initial)
        let water = entry(.water, value: 3)
        let cloud = PausedHabitCloud(data: data([coffee, water]))
        let dataStore = CloudKitHabitDataStore(cache: reopened, cloud: cloud)
        try await dataStore.synchronize()
        #expect(try await reopened.load().entries == [water])
        #expect(await cloud.currentStore.entries == [water])
    }

    @Test func deletionDuringUploadRemainsPendingAfterTheUploadFinishes() async throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let cache = FileHabitDataStore(fileURL: file)
        let coffee = entry(.coffee, value: 1)
        let atStart = data([coffee])
        try await cache.seed(atStart)
        try await cache.seed(data([]))
        try await cache.acceptSynchronizedData(atStart, localAtStart: atStart)
        let document = try await cache.readDocument()
        #expect(document.data.entries.isEmpty)
        #expect(document.lastSynchronizedData == atStart)
        let cloud = PausedHabitCloud(data: atStart)
        try await CloudKitHabitDataStore(cache: cache, cloud: cloud).synchronize()
        #expect(await cloud.currentStore.entries.isEmpty)
    }

    @Test func differentDaysAndRemoteDeletionArePreserved() async throws {
        let merge = HabitDataChanges(calendar: .current)
        let yesterday = entry(.coffee, value: 2, on: date.addingTimeInterval(-86_400))
        let today = entry(.coffee, value: 3)
        let water = entry(.water, value: 4)
        let result = merge.apply(from: data([yesterday]), to: data([yesterday, today]), onto: data([water]))
        #expect(result.entries.count == 2)
        #expect(result.entries.contains(today))
        #expect(result.entries.contains(water))
        #expect(!result.entries.contains(yesterday))
    }

    @Test func pendingLocalEditWinsWhenBothDevicesEditTheSameDay() async throws {
        let merge = HabitDataChanges(calendar: .current)
        let original = entry(.coffee, value: 1)
        let local = entry(.coffee, value: 2)
        let remote = entry(.coffee, value: 3)
        let result = merge.apply(from: data([original]), to: data([local]), onto: data([remote]))
        #expect(result.entries == [local])
    }

    @Test func independentHabitSelectionsAreMerged() async throws {
        let merge = HabitDataChanges(calendar: .current)
        let before = HabitData(enabledHabits: [Habit(type: .coffee)], entries: [])
        let local = HabitData(enabledHabits: [Habit(type: .water)], entries: [])
        let remote = HabitData(enabledHabits: [Habit(type: .coffee), Habit(type: .sleep)], entries: [])
        let result = merge.apply(from: before, to: local, onto: remote)
        #expect(Set(result.enabledHabits.map(\.id)) == [Habit(type: .water).id, Habit(type: .sleep).id])
    }

    @Test func failingLocalWriteDoesNotPublishAnUnsavedEntry() async throws {
        let file = temporaryFile()
        let directory = file.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let cache = FileHabitDataStore(fileURL: file)
        try await cache.seed(data([]))
        let manager = HabitsManager(storage: CloudKitHabitDataStore(cache: cache, cloud: PausedHabitCloud(data: data([]))), currentDate: { date })
        await manager.load()
        // Replace the destination with a directory, so a file write must fail.
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        do {
            try await manager.recordCoffee()
            #expect(false)
        } catch {}
        #expect(manager.entries.isEmpty)
    }

    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "habits.json")
    }

    private func entry(_ type: Habit.HabitType, value: Double, on day: Date? = nil) -> HabitEntry {
        HabitEntry(id: UUID(), habitType: type, date: day ?? date, value: value)
    }

    private func data(_ entries: [HabitEntry]) -> HabitData {
        HabitData(enabledHabits: [Habit(type: .coffee), Habit(type: .water)], entries: entries)
    }
}

private actor PausedHabitCloud: HabitCloudClient {
    private(set) var currentStore: HabitData
    private(set) var requestCount = 0
    private var shouldPause = false
    private var shouldFail = false
    private var paused: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?

    init(data: HabitData) { currentStore = data }

    func merge(_ local: HabitData, since previous: HabitData?) async throws -> HabitData {
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
        currentStore = HabitDataChanges(calendar: .current).apply(
            from: previous ?? HabitData(enabledHabits: [], entries: []), to: local, onto: currentStore)
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

private extension FileHabitDataStore {
    func seed(_ data: HabitData) async throws {
        _ = try await save(data, replacing: load())
    }
}
