// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct WeightLogManagerTests {
    @Test func addingEntryPersistsCanonicalKilograms() async throws {
        let repository = InMemoryWeightRepository()
        let manager = WeightLogManager(repository: repository)
        await manager.load()
        try await manager.add(
            WeightEntryDraft(date: .now, value: "75.5", note: " Test "),
            unit: .kilograms
        )
        let stored = try await repository.load()
        #expect(stored.entries.first?.kilograms == 75.5)
        #expect(stored.entries.first?.note == "Test")
    }

    @Test func overlappingSavesRetainEveryEntry() async throws {
        let repository = InMemoryWeightRepository()
        let manager = WeightLogManager(repository: repository)
        let tasks = (0..<20).map { index in
            Task { @MainActor in
                try await manager.add(WeightEntryDraft(date: .now, value: "\(70 + index)"), unit: .kilograms)
            }
        }
        for task in tasks { try await task.value }
        #expect(manager.entries.count == 20)
        #expect(try await repository.load().entries.count == 20)
    }
}
