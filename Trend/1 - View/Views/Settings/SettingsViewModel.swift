// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let settings: any SettingsFeature

    var exportDocument: JSONDocument?
    var isExporting = false
    var isImporting = false
    var confirmDelete = false
    var message: String?
    var goalText = ""

    init(settings: any SettingsFeature = AppBrain.shared.settingsFeature) {
        self.settings = settings
        updateGoalText()
    }

    var unit: WeightUnit {
        get { settings.selectedWeightUnit }
        set {
            settings.setWeightUnit(newValue)
            updateGoalText()
        }
    }
    var cloudStatus: CloudSyncStatus { settings.cloudSyncStatus }
    var canSaveGoal: Bool {
        settings.canSetGoal(from: goalText)
    }

    func refreshCloudStatus() async { await settings.refreshCloudStatus() }

    func prepareExport() async {
        do {
            exportDocument = JSONDocument(data: try await settings.exportData())
            isExporting = true
        } catch {
            message = error.localizedDescription
        }
    }

    func importFile(_ result: Result<URL, Error>) async {
        do {
            let url = try result.get()
            try await settings.importData(from: url)
            updateGoalText()
            message = "Backup imported."
        } catch {
            message = error.localizedDescription
        }
    }

    func saveGoal() async {
        do {
            try await settings.setGoal(from: goalText)
        } catch {
            message = error.localizedDescription
        }
    }

    func deleteAllData() async {
        do {
            try await settings.deleteAllData()
            goalText = ""
        } catch {
            message = error.localizedDescription
        }
    }

    private func updateGoalText() {
        guard let goal = settings.goalWeightKilograms else {
            goalText = ""
            return
        }
        goalText = unit.value(fromKilograms: goal).formatted(.number.precision(.fractionLength(1)))
    }
}
