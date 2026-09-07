// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

enum WeightLogState: Equatable {
    case idle
    case loading
    case ready
    case failed(String)
}

@MainActor
@Observable
final class WeightLogManager {
    private let repository: any WeightRepository
    private(set) var state: WeightLogState = .idle
    private(set) var entries: [WeightEntry] = []
    private(set) var goalKilograms: Double?

    var latestEntry: WeightEntry? { entries.first }

    init(repository: any WeightRepository) { self.repository = repository }

    func load() async {
        state = .loading
        do {
            if let repository = repository as? any LocallyCachedWeightRepository {
                let localStore = try await repository.loadCached()
                publish(localStore)
                state = .ready

                let synchronizedStore = await repository.synchronize(localStore)
                publish(synchronizedStore)
            } else {
                publish(try await repository.load())
            }
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func add(_ draft: WeightEntryDraft, unit: WeightUnit) async throws {
        var candidate = store
        candidate.entries.append(WeightEntry(
            date: draft.date,
            kilograms: try draft.kilograms(using: unit),
            note: draft.note.trimmed
        ))
        try await commit(candidate)
    }

    func update(_ entry: WeightEntry, with draft: WeightEntryDraft, unit: WeightUnit) async throws {
        var candidate = store
        guard let index = candidate.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        candidate.entries[index].date = draft.date
        candidate.entries[index].kilograms = try draft.kilograms(using: unit)
        candidate.entries[index].note = draft.note.trimmed
        try await commit(candidate)
    }

    func delete(_ entry: WeightEntry) async throws {
        var candidate = store
        candidate.entries.removeAll { $0.id == entry.id }
        try await commit(candidate)
    }

    /// Stores goals in canonical kilograms. SettingsManager converts a value
    /// entered in pounds before it reaches this persistence boundary.
    func setGoal(kilograms: Double?) async throws {
        var candidate = store
        candidate.goalKilograms = kilograms
        try await commit(candidate)
    }

    func replace(with store: WeightStore) async throws { try await commit(store) }
    func removeAll() async throws { try await commit(WeightStore(entries: [], goalKilograms: nil)) }

    var store: WeightStore { WeightStore(entries: entries, goalKilograms: goalKilograms) }

    private func commit(_ candidate: WeightStore) async throws {
        let sorted = WeightStore(
            entries: candidate.entries.sorted { $0.date > $1.date },
            goalKilograms: candidate.goalKilograms
        )
        try await repository.save(sorted)
        publish(sorted)
        state = .ready
    }

    private func publish(_ store: WeightStore) {
        entries = store.entries.sorted { $0.date > $1.date }
        goalKilograms = store.goalKilograms
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
