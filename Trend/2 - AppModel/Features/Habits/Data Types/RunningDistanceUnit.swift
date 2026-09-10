// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

enum RunningDistanceUnit: String, CaseIterable, Identifiable, Sendable {
    case kilometres
    case miles

    var id: Self { self }
    var title: String { rawValue.capitalized }

    func value(fromKilometres kilometres: Double) -> Double {
        self == .kilometres ? kilometres : kilometres / 1.609_344
    }

    func kilometres(from value: Double) -> Double {
        self == .kilometres ? value : value * 1.609_344
    }
}
