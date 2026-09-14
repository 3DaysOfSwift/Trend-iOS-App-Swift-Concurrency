// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct RunEntryView: View {
    @State private var viewModel = RunEntryViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.didSave {
                Label("Run recorded", systemImage: "checkmark.circle.fill").font(.headline)
                Button("Record another run", action: viewModel.recordAnother).font(.footnote)
            } else {
                Text("How far did you run?").font(.headline)
                Picker("Distance unit", selection: $viewModel.unit) {
                    ForEach(RunningDistanceUnit.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented)
                HStack {
                    TextField("Distance", value: $viewModel.distance, format: .number)
                        .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Running distance")
                    Stepper("Adjust distance", value: $viewModel.distance,
                            in: viewModel.habit.recordingPolicy.range, step: viewModel.habit.recordingPolicy.step)
                        .labelsHidden()
                }
                Button { Task { await viewModel.save() } } label: {
                    if viewModel.isSaving { SwiftUI.ProgressView() }
                    else { Text("Record this run") }
                }.buttonStyle(.borderedProminent)
            }
        }
        .disabled(viewModel.isSaving)
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .sensoryFeedback(.success, trigger: viewModel.didSave)
    }
}
