// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Testing
@testable import Trend

@MainActor
struct WeightKeyboardInputViewModelTests {
    @Test func describesEmptyInputWithoutInventingAWeight() {
        #expect(WeightKeyboardInputViewModel().accessibilityValue(text: "", unit: .kilograms) == "Not entered")
    }

    @Test func describesEnteredValueInTheSelectedUnit() {
        let viewModel = WeightKeyboardInputViewModel()
        #expect(viewModel.accessibilityValue(text: "69.7", unit: .kilograms) == "69.7 kg")
        #expect(viewModel.accessibilityValue(text: "153.7", unit: .pounds) == "153.7 lb")
    }
}
