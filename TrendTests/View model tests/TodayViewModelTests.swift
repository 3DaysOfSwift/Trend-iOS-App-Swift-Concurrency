// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct TodayViewModelTests {
    @Test func newDraftAndDateBoundaryComeFromAppBrainClock() {
        let now = Date(timeIntervalSince1970: 1_000)
        let viewModel = TodayViewModel(
            today: TestAppBrainFactory.make(currentDate: { now }).weightEntries
        )

        #expect(viewModel.draft.date == now)
        #expect(viewModel.latestPermittedEntryDate == now)
    }

    @Test func emptyStateHasNoLatestEntryOrChange() {
        let viewModel = TodayViewModel(today: TestAppBrainFactory.make().weightEntries)

        #expect(viewModel.latestEntry == nil)
        #expect(viewModel.changeKilograms == nil)
        #expect(viewModel.unit == .kilograms)
    }

    @Test func exposesLatestEntryTrendAndUnit() async {
        let now = Date()
        let older = WeightEntry(date: now.addingTimeInterval(-86_400), kilograms: 82)
        let latest = WeightEntry(date: now, kilograms: 80)
        let repository = InMemoryWeightRepository(store: .init(entries: [older, latest], goalKilograms: nil))
        let brain = TestAppBrainFactory.make(repository: repository, unit: .pounds)
        await brain.start()
        let viewModel = TodayViewModel(today: brain.weightEntries)

        #expect(viewModel.latestEntry == latest)
        #expect(viewModel.changeKilograms == -2)
        #expect(viewModel.unit == .pounds)
    }

    @Test func savingWeightPublishesEntryAndClearsDraft() async {
        let repository = InMemoryWeightRepository()
        let brain = TestAppBrainFactory.make(repository: repository)
        let viewModel = TodayViewModel(today: brain.weightEntries)
        viewModel.draft = WeightEntryDraft(
            date: Date(timeIntervalSince1970: 456),
            value: "72.5",
            note: " Morning "
        )

        let didSave = await viewModel.save()

        #expect(didSave)
        #expect(brain.weightEntries.latestWeightEntry?.kilograms == 72.5)
        #expect(brain.weightEntries.latestWeightEntry?.note == "Morning")
        #expect(viewModel.draft.value.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isSaving)
        #expect(viewModel.submittedResult != nil)
    }

    @Test func invalidWeightRemainsInDraftAndShowsMessage() async {
        let viewModel = TodayViewModel(today: TestAppBrainFactory.make().weightEntries)
        viewModel.draft.value = "invalid"

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.draft.value == "invalid")
        #expect(viewModel.errorMessage == "Enter a weight between 20 and 500 kg.")
        #expect(!viewModel.isSaving)
    }

    @Test func persistenceFailureKeepsEnteredWeightForRetry() async {
        let repository = InMemoryWeightRepository(saveError: .saveFailed)
        let viewModel = TodayViewModel(today: TestAppBrainFactory.make(repository: repository).weightEntries)
        viewModel.draft.value = "75"

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.draft.value == "75")
        #expect(viewModel.errorMessage == "The test repository could not save.")
    }
}
