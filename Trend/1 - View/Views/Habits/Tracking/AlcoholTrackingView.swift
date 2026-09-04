// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct AlcoholTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .alcohol)
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "wineglass.fill")
                .font(.system(size: 104))
                .foregroundStyle(.purple.gradient)
            Text("\(Int(viewModel.todayValue))")
                .font(.system(size: 82, weight: .bold, design: .rounded).monospacedDigit())
            Text(viewModel.todayValue == 1 ? "drink today" : "drinks today")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Record a drink", systemImage: "plus.circle.fill") {
                Task { await viewModel.increment() }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Text("Simply observe. Trend will help you see the pattern.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Alcohol")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(viewModel)
        .safeAreaInset(edge: .top, spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)
        }
    }
}
