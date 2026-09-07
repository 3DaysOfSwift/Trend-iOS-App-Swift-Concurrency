// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

/// The validated input accepted by weight-log workflows.
///
/// Views may build and edit this plain value, but AppModel owns its meaning and
/// conversion into the canonical kilograms stored by the repository.
struct WeightEntryDraft: Sendable {
    var date = Date()
    var value = ""
    var note = ""

    func kilograms(using unit: WeightUnit) throws -> Double {
        try unit.kilograms(from: value)
    }
}
