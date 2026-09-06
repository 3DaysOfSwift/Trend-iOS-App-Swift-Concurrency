// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct WeightEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var date: Date
    var kilograms: Double
    var note: String

    init(id: UUID = UUID(), date: Date, kilograms: Double, note: String = "") {
        self.id = id
        self.date = date
        self.kilograms = kilograms
        self.note = note
    }
}
