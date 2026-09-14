// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct TodayViewModelTests {
    @Test func habitsRequireWeightRecordedForTodayAndSurviveViewRecreation() async {
        let now = Date()
        let appModel = TestAppModelFactory.make(currentDate: { now })
        await appModel.weightEntries.refresh()
        let viewModel = TodayViewModel(today: appModel.weightEntries)
        #expect(!viewModel.showsHabits)

        viewModel.draft = WeightEntryDraft(
            date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
            value: "72.5", note: ""
        )
        #expect(await viewModel.save())
        #expect(!viewModel.showsHabits)

        viewModel.draft = WeightEntryDraft(date: now, value: "72.4", note: "")
        #expect(await viewModel.save())
        #expect(viewModel.showsHabits)
        #expect(TodayViewModel(today: appModel.weightEntries).showsHabits)
    }

    @Test func newDraftAndDateBoundaryComeFromAppModelClock() {
        let now = Date(timeIntervalSince1970: 1_000)
        let viewModel = TodayViewModel(
            today: TestAppModelFactory.make(currentDate: { now }).weightEntries
        )

        #expect(viewModel.draft.date == now)
        #expect(viewModel.latestPermittedEntryDate == now)
    }

    @Test func emptyStateHasNoLatestEntryOrChange() {
        let viewModel = TodayViewModel(today: TestAppModelFactory.make().weightEntries)

        #expect(viewModel.latestEntry == nil)
        #expect(viewModel.changeKilograms == nil)
        #expect(viewModel.unit == .kilograms)
    }

    @Test func exposesLatestEntryTrendAndUnit() async {
        let now = Date()
        let older = WeightEntry(date: now.addingTimeInterval(-86_400), kilograms: 82)
        let latest = WeightEntry(date: now, kilograms: 80)
        let repository = InMemoryWeightRepository(store: .init(entries: [older, latest], goalKilograms: nil))
        let appModel = TestAppModelFactory.make(repository: repository, unit: .pounds)
        await appModel.weightEntries.refresh()
        let viewModel = TodayViewModel(today: appModel.weightEntries)

        #expect(viewModel.latestEntry == latest)
        #expect(viewModel.changeKilograms == -2)
        #expect(viewModel.unit == .pounds)
    }

    @Test func savingWeightPublishesEntryAndKeepsSubmittedDraft() async {
        let repository = InMemoryWeightRepository()
        let appModel = TestAppModelFactory.make(repository: repository)
        let viewModel = TodayViewModel(today: appModel.weightEntries)
        viewModel.draft = WeightEntryDraft(
            date: Date(timeIntervalSince1970: 456),
            value: "72.5",
            note: " Morning "
        )

        let didSave = await viewModel.save()

        #expect(didSave)
        #expect(appModel.weightEntries.latestWeightEntry?.kilograms == 72.5)
        #expect(appModel.weightEntries.latestWeightEntry?.note == "Morning")
        #expect(viewModel.draft.value == "72.5")
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isSaving)
        #expect(viewModel.submittedResult != nil)
    }

    @Test func beginningAnotherCheckInCreatesFreshDraft() async {
        let viewModel = TodayViewModel(today: TestAppModelFactory.make().weightEntries)
        viewModel.draft.value = "72.5"

        #expect(await viewModel.save())
        viewModel.beginAnotherCheckIn()

        #expect(viewModel.draft.value == "72.5")
        #expect(viewModel.submittedResult == nil)
    }

    @Test func invalidWeightRemainsInDraftAndShowsMessage() async {
        let viewModel = TodayViewModel(today: TestAppModelFactory.make().weightEntries)
        viewModel.draft.value = "invalid"

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.draft.value == "invalid")
        #expect(viewModel.errorMessage == "Enter a weight between 20 and 500 kg.")
        #expect(!viewModel.isSaving)
    }

    @Test func loadSeedsLatestWeightWithoutCopyingOldDateOrNote() async {
        let now = Date(timeIntervalSince1970: 100_000)
        let previous = WeightEntry(date: now.addingTimeInterval(-86_400), kilograms: 69.7, note: "Yesterday")
        let app = TestAppModelFactory.make(repository: InMemoryWeightRepository(
            store: .init(entries: [previous], goalKilograms: nil)), currentDate: { now })
        let viewModel = TodayViewModel(today: app.weightEntries)
        await viewModel.refresh()
        viewModel.prepareWeightInput()
        #expect(viewModel.draft.value == "69.7")
        #expect(viewModel.draft.date == now)
        #expect(viewModel.draft.note.isEmpty)
        viewModel.draft.value = "69.6"
        viewModel.prepareWeightInput()
        #expect(viewModel.draft.value == "69.6")
        #expect(app.weightEntries.entries.count == 1)
    }

    @Test func changingUnitsConvertsDraftRatherThanRelabelingItsNumber() async {
        let app = TestAppModelFactory.make()
        let viewModel = TodayViewModel(today: app.weightEntries)
        viewModel.draft.value = "45.359237"
        app.settingsFeature.setWeightUnit(.pounds)
        viewModel.updateInputUnit()
        #expect(viewModel.draft.value == "100.0")
    }

    @Test func persistenceFailureKeepsEnteredWeightForRetry() async {
        let repository = InMemoryWeightRepository(saveError: .saveFailed)
        let viewModel = TodayViewModel(today: TestAppModelFactory.make(repository: repository).weightEntries)
        viewModel.draft.value = "75"

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.draft.value == "75")
        #expect(viewModel.errorMessage == "The test repository could not save.")
    }
}
