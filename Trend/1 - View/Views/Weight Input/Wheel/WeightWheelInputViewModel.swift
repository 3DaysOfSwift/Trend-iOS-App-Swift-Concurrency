// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

/// Digit layout and text formatting only. Validation and unit conversion remain
/// in the weight feature. No entry is saved when a wheel moves.
@MainActor @Observable
final class WeightWheelInputViewModel {
    var decimalSeparator: String { Locale.current.decimalSeparator ?? "." }

    func maximumWholeValue(for unit: WeightUnit) -> Int {
        Int(unit.value(fromKilograms: WeightUnit.maximumKilograms))
    }

    func canDisplay(_ text: String, unit: WeightUnit) -> Bool {
        if text.isEmpty { return true }
        guard let number = number(text), number >= 0 else { return false }
        let maximum = Double(maximumWholeValue(for: unit)) + 0.9
        return number <= maximum && abs(number * 10 - (number * 10).rounded()) < 0.000001
    }

    func wholeValue(in text: String) -> Int {
        guard let number = number(text), number >= 0, number < 10000 else { return 0 }
        return Int((number * 10).rounded()) / 10
    }

    func tenths(in text: String) -> Int {
        guard let number = number(text), number >= 0, number < 10000 else { return 0 }
        return Int((number * 10).rounded()) % 10
    }

    func replacingWholeValue(with whole: Int, in text: String, unit: WeightUnit) -> String {
        guard (0...maximumWholeValue(for: unit)).contains(whole) else { return text }
        return "\(whole)\(decimalSeparator)\(tenths(in: text))"
    }

    func replacingTenths(with digit: Int, in text: String) -> String {
        guard (0...9).contains(digit) else { return text }
        return "\(wholeValue(in: text))\(decimalSeparator)\(digit)"
    }

    private func number(_ text: String) -> Double? {
        guard let value = Double(text.replacingOccurrences(of: ",", with: ".")), value.isFinite else { return nil }
        return value
    }
}
