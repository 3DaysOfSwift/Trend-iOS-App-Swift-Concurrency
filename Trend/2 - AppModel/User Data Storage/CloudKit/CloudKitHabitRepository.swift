// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor CloudKitHabitRepository: HabitCloudSynchronizing {
    private let cache: FileHabitRepository
    private let cloud: any HabitCloudClient

    init(cache: FileHabitRepository, cloud: any HabitCloudClient) {
        self.cache = cache
        self.cloud = cloud
    }

    // Loading and saving use the device only. A slow network must not delay a local edit.
    func load() async throws -> HabitStore { try await cache.load() }

    func save(_ store: HabitStore) async throws { try await cache.save(store) }

    func save(_ store: HabitStore, replacing previous: HabitStore) async throws -> HabitStore {
        try await cache.save(store, replacing: previous)
    }

    // HabitsManager owns the shared synchronization task. No cancel-and-restart uploads.
    func synchronize() async throws {
        let document = try await cache.readDocument()
        let synchronized = try await cloud.merge(document.store, since: document.lastSynchronizedStore)
        try await cache.acceptSynchronizedStore(synchronized, localAtStart: document.store)
    }
}
