// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

@MainActor
protocol ProgressFeature: AnyObject {
    var progressSnapshot: ProgressSnapshot { get }
    var goalWeightKilograms: Double? { get }
    var selectedWeightUnit: WeightUnit { get }
    var isPreparingProgress: Bool { get }
    var selectedProgressRange: ProgressRange { get }

    func selectProgressRange(_ range: ProgressRange)
}
