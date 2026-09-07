// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

actor InMemoryWeightRepository: WeightRepository, CloudSyncStatusProviding {
    enum TestError: LocalizedError {
        case loadFailed
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .loadFailed: "The test repository could not load."
            case .saveFailed: "The test repository could not save."
            }
        }
    }

    private var store: WeightStore
    private let loadError: TestError?
    private let saveError: TestError?
    private let status: CloudSyncStatus
    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0

    init(
        store: WeightStore = .init(entries: [], goalKilograms: nil),
        loadError: TestError? = nil,
        saveError: TestError? = nil,
        cloudStatus: CloudSyncStatus = .unavailable
    ) {
        self.store = store
        self.loadError = loadError
        self.saveError = saveError
        status = cloudStatus
    }

    func load() async throws -> WeightStore {
        loadCallCount += 1
        if let loadError { throw loadError }
        return store
    }

    func save(_ store: WeightStore) async throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        self.store = store
    }

    func cloudStatus() async -> CloudSyncStatus { status }
}
