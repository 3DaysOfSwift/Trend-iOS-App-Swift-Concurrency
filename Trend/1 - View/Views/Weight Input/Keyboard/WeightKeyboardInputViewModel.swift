// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Observation

@MainActor @Observable
final class WeightKeyboardInputViewModel {
    func accessibilityValue(text: String, unit: WeightUnit) -> String {
        text.isEmpty ? "Not entered" : "\(text) \(unit.symbol)"
    }
}
