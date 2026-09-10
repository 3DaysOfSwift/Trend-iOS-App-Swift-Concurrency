// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor CloudKitHabitDataStore: HabitCloudSynchronizing {
    private let cache: FileHabitDataStore
    private let cloud: any HabitCloudClient

    init(cache: FileHabitDataStore, cloud: any HabitCloudClient) {
        self.cache = cache
        self.cloud = cloud
    }

    // Loading and saving use the device only. A slow network must not delay a local edit.
    func load() async throws -> HabitData { try await cache.load() }

    func save(_ data: HabitData, replacing previous: HabitData) async throws -> HabitData {
        try await cache.save(data, replacing: previous)
    }

    // HabitsManager owns the shared synchronization task. No cancel-and-restart uploads.
    func synchronize() async throws {
        let document = try await cache.readDocument()
        let synchronized = try await cloud.merge(document.data, since: document.lastSynchronizedData)
        try await cache.acceptSynchronizedData(synchronized, localAtStart: document.data)
    }
}
