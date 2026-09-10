// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class ProgressViewModel {
    private let progress: ProgressManager

    init(progress: ProgressManager = AppModel.shared.progressFeature) {
        self.progress = progress
    }

    var snapshot: WeightHistoryData { progress.progressSnapshot }
    var goalKilograms: Double? { progress.goalWeightKilograms }
    var unit: WeightUnit { progress.selectedWeightUnit }
    var isLoading: Bool { progress.isPreparingProgress }
    var range: ProgressRange {
        get { progress.selectedProgressRange }
        set { progress.selectProgressRange(newValue) }
    }
}
