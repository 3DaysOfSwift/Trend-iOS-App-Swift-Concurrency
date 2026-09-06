// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct SettingsViewModelTests {
    @Test func initialStateReflectsStoredGoalAndUnit() async {
        let repository = InMemoryWeightRepository(store: .init(entries: [], goalKilograms: 70))
        let brain = TestAppBrainFactory.make(repository: repository)
        await brain.applicationDidFinishLaunching()

        let viewModel = SettingsViewModel(settings: brain.settingsFeature)

        #expect(viewModel.unit == .kilograms)
        #expect(viewModel.goalText == "70.0")
        #expect(viewModel.cloudStatus == .unavailable)
        #expect(!viewModel.isExporting)
        #expect(!viewModel.isImporting)
        #expect(!viewModel.confirmDelete)
    }

    @Test func changingUnitConvertsGoalText() async {
        let repository = InMemoryWeightRepository(store: .init(entries: [], goalKilograms: 45.359237))
        let brain = TestAppBrainFactory.make(repository: repository)
        await brain.applicationDidFinishLaunching()
        let viewModel = SettingsViewModel(settings: brain.settingsFeature)

        viewModel.unit = .pounds

        #expect(viewModel.unit == .pounds)
        #expect(viewModel.goalText == "100.0")
    }

    @Test func refreshCloudStatusPublishesProviderValue() async {
        let repository = InMemoryWeightRepository(cloudStatus: .available)
        let viewModel = SettingsViewModel(settings: TestAppBrainFactory.make(repository: repository).settingsFeature)

        await viewModel.refreshCloudStatus()

        #expect(viewModel.cloudStatus == .available)
    }

    @Test func validGoalIsSavedInCanonicalKilograms() async {
        let repository = InMemoryWeightRepository()
        let brain = TestAppBrainFactory.make(repository: repository, unit: .pounds)
        let viewModel = SettingsViewModel(settings: brain.settingsFeature)
        viewModel.goalText = "154.3"

        await viewModel.saveGoal()

        #expect(abs((brain.settingsFeature.goalWeightKilograms ?? 0) - 69.989) < 0.01)
        #expect(viewModel.message == nil)
    }

    @Test func invalidGoalShowsValidationMessage() async {
        let viewModel = SettingsViewModel(settings: TestAppBrainFactory.make().settingsFeature)
        viewModel.goalText = "10"

        await viewModel.saveGoal()

        #expect(viewModel.message == "Enter a weight between 20 and 500 kg.")
    }

    @Test func goalSaveAvailabilityUsesTheSameValidationAsSaving() {
        let viewModel = SettingsViewModel(settings: TestAppBrainFactory.make().settingsFeature)

        viewModel.goalText = "10"
        #expect(!viewModel.canSaveGoal)

        viewModel.goalText = "70"
        #expect(viewModel.canSaveGoal)
    }

    @Test func exportProducesJSONDocumentAndOpensExporter() async {
        let repository = InMemoryWeightRepository(store: .init(entries: [], goalKilograms: 70))
        let brain = TestAppBrainFactory.make(repository: repository)
        await brain.applicationDidFinishLaunching()
        let viewModel = SettingsViewModel(settings: brain.settingsFeature)

        await viewModel.prepareExport()

        #expect(viewModel.exportDocument != nil)
        #expect(viewModel.isExporting)
        #expect(viewModel.message == nil)
    }

    @Test func importPickerFailureIsPresented() async {
        let viewModel = SettingsViewModel(settings: TestAppBrainFactory.make().settingsFeature)
        let error = CocoaError(.fileReadCorruptFile)

        await viewModel.importFile(.failure(error))

        #expect(viewModel.message == error.localizedDescription)
    }

    @Test func deleteAllClearsEntriesGoalAndText() async {
        let entry = WeightEntry(date: .now, kilograms: 80)
        let repository = InMemoryWeightRepository(store: .init(entries: [entry], goalKilograms: 70))
        let brain = TestAppBrainFactory.make(repository: repository)
        await brain.applicationDidFinishLaunching()
        let viewModel = SettingsViewModel(settings: brain.settingsFeature)

        await viewModel.deleteAllData()

        #expect(brain.weightEntries.entries.isEmpty)
        #expect(brain.settingsFeature.goalWeightKilograms == nil)
        #expect(viewModel.goalText.isEmpty)
    }

    @Test func deleteFailurePreservesDataAndShowsMessage() async {
        let entry = WeightEntry(date: .now, kilograms: 80)
        let repository = InMemoryWeightRepository(
            store: .init(entries: [entry], goalKilograms: 70),
            saveError: .saveFailed
        )
        let brain = TestAppBrainFactory.make(repository: repository)
        await brain.applicationDidFinishLaunching()
        let viewModel = SettingsViewModel(settings: brain.settingsFeature)

        await viewModel.deleteAllData()

        #expect(brain.weightEntries.entries == [entry])
        #expect(viewModel.goalText == "70.0")
        #expect(viewModel.message == "The test repository could not save.")
    }
}
