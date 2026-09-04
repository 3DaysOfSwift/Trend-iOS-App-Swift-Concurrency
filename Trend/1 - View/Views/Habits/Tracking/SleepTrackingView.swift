// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct SleepTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .sleep)
    @Environment(ThemeManager.self) private var themeManager
    @State private var hours = 8.0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 100))
                .foregroundStyle(.indigo.gradient)
            Text(hours.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 78, weight: .bold, design: .rounded).monospacedDigit())
            Text("hours of sleep").font(.title3).foregroundStyle(.secondary)
            Slider(value: $hours, in: 0...14, step: 0.5)
                .padding(.horizontal, 32)
            Button("Record my sleep", systemImage: "bed.double.fill") {
                Task { await viewModel.record(hours) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if viewModel.hasCheckedInToday { hours = viewModel.todayValue } }
        .habitErrorAlert(viewModel)
    }
}
