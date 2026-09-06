// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct EntryEditorViewModelTests {
    @Test func newDraftAndDateBoundaryComeFromAppBrainClock() {
        let now = Date(timeIntervalSince1970: 1_000)
        let viewModel = EntryEditorViewModel(
            editor: TestAppBrainFactory.make(currentDate: { now }).weightEntries
        )

        #expect(viewModel.draft.date == now)
        #expect(viewModel.latestPermittedEntryDate == now)
    }

    @Test func newEntryStartsEmptyAndUsesCurrentUnit() {
        let brain = TestAppBrainFactory.make(unit: .pounds)
        let viewModel = EntryEditorViewModel(editor: brain.weightEntries)

        #expect(viewModel.title == "Log Weight")
        #expect(viewModel.draft.value.isEmpty)
        #expect(viewModel.unit == .pounds)
        #expect(!viewModel.canSave)
        #expect(!viewModel.isSaving)
    }

    @Test func existingEntryPopulatesEditableDraft() {
        let entry = WeightEntry(date: Date(timeIntervalSince1970: 123), kilograms: 70, note: "Morning")
        let brain = TestAppBrainFactory.make()
        let viewModel = EntryEditorViewModel(editor: brain.weightEntries, entry: entry)

        #expect(viewModel.title == "Edit Entry")
        #expect(viewModel.draft.date == entry.date)
        #expect(viewModel.draft.value == "70.0")
        #expect(viewModel.draft.note == "Morning")
    }

    @Test func savingNewEntryPersistsAndDismisses() async {
        let repository = InMemoryWeightRepository()
        let brain = TestAppBrainFactory.make(repository: repository)
        let viewModel = EntryEditorViewModel(editor: brain.weightEntries)
        viewModel.draft = WeightEntryDraft(date: Date(timeIntervalSince1970: 456), value: "72.5", note: " Evening ")

        let didSave = await viewModel.save()

        #expect(didSave)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isSaving)
        #expect(brain.weightEntries.latestWeightEntry?.kilograms == 72.5)
        #expect(brain.weightEntries.latestWeightEntry?.note == "Evening")
    }

    @Test func savingExistingEntryUpdatesIt() async {
        let entry = WeightEntry(date: .now, kilograms: 80)
        let repository = InMemoryWeightRepository(store: .init(entries: [entry], goalKilograms: nil))
        let brain = TestAppBrainFactory.make(repository: repository)
        await brain.applicationDidFinishLaunching()
        let viewModel = EntryEditorViewModel(editor: brain.weightEntries, entry: entry)
        viewModel.draft.value = "79"

        let didSave = await viewModel.save()

        #expect(didSave)
        #expect(brain.weightEntries.entries.count == 1)
        #expect(brain.weightEntries.latestWeightEntry?.kilograms == 79)
    }

    @Test func invalidWeightShowsValidationAndDoesNotDismiss() async {
        let brain = TestAppBrainFactory.make()
        let viewModel = EntryEditorViewModel(editor: brain.weightEntries)
        viewModel.draft.value = "not a number"

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.errorMessage == "Enter a weight between 20 and 500 kg.")
        #expect(!viewModel.isSaving)
    }

    @Test func repositoryFailureIsPresentedAndDoesNotDismiss() async {
        let repository = InMemoryWeightRepository(saveError: .saveFailed)
        let brain = TestAppBrainFactory.make(repository: repository)
        let viewModel = EntryEditorViewModel(editor: brain.weightEntries)
        viewModel.draft.value = "75"

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.errorMessage == "The test repository could not save.")
    }
}
