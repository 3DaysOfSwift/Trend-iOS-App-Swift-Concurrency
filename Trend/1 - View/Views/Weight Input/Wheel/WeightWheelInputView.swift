// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct WeightWheelInputView: View {
    @State private var viewModel = WeightWheelInputViewModel()
    @Binding var value: String
    let unit: WeightUnit
    let useKeyboard: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            if viewModel.canDisplay(value, unit: unit) {
                GeometryReader { geometry in
                    let availableWidth = max(1, geometry.size.width - 18)
                    HStack(spacing: 0) {
                        WeightNumberWheelView(selection: Binding(
                            get: { viewModel.wholeValue(in: value) },
                            set: { value = viewModel.replacingWholeValue(with: $0, in: value, unit: unit) }
                        ), label: "Whole \(unit.symbol)", maximum: viewModel.maximumWholeValue(for: unit),
                           repeats: false, width: availableWidth * 0.7)

                        Text(viewModel.decimalSeparator)
                            .font(.system(size: 72, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 18)
                            .offset(y: 26)
                            .accessibilityHidden(true)

                        WeightNumberWheelView(selection: Binding(
                            get: { viewModel.tenths(in: value) },
                            set: { value = viewModel.replacingTenths(with: $0, in: value) }
                        ), label: "Tenths", maximum: 9, repeats: true, width: availableWidth * 0.3)
                    }
                }
                .frame(height: 190)
                .environment(\.layoutDirection, .leftToRight)
                .environment(\.colorScheme, .dark)

            } else {
                // Never round or clamp an existing keyboard entry silently.
                Text(value)
                    .font(.largeTitle.monospacedDigit())
                    .foregroundStyle(.white)
                Button("Edit this value with the keyboard", action: useKeyboard)
                    .font(.subheadline)
                    .tint(.white)
            }
        }
        .sensoryFeedback(.selection, trigger: value)
    }

}
