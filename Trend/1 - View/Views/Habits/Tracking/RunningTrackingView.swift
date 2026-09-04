// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct RunningTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .runningDistance)
    @Environment(ThemeManager.self) private var themeManager
    @State private var distance = 5.0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 112))
                .foregroundStyle(themeManager.palette.accent)
            Text(distance.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 78, weight: .bold, design: .rounded).monospacedDigit())
            Text("kilometres").font(.title3).foregroundStyle(.secondary)
            Slider(value: $distance, in: 0...30, step: 0.1)
                .padding(.horizontal, 32)
            Button("Record this run", systemImage: "checkmark.circle.fill") {
                Task { await viewModel.record(distance) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Running")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if viewModel.hasCheckedInToday { distance = viewModel.todayValue } }
        .habitErrorAlert(viewModel)
        .safeAreaInset(edge: .top, spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)
        }
    }
}
