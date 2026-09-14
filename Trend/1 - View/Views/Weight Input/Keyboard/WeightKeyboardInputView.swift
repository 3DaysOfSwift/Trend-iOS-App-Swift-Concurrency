// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

/// Edits a draft only. The owning screen decides when to submit it.
struct WeightKeyboardInputView: View {
    @State private var viewModel = WeightKeyboardInputViewModel()
    @Binding var value: String
    let unit: WeightUnit
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        TextField("0.0", text: $value,
                  prompt: Text("0.0").foregroundStyle(.white.opacity(0.24)))
            .keyboardType(.decimalPad)
            .focused(isFocused)
            .multilineTextAlignment(.center)
            .font(.system(size: 104, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .tint(.white)
            .minimumScaleFactor(0.42)
            .lineLimit(1)
            .accessibilityLabel("Weight")
            .accessibilityValue(viewModel.accessibilityValue(text: value, unit: unit))
    }
}
