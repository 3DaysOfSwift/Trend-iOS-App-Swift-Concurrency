// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct AlcoholTrackingView: View {
    @State private var viewModel = AlcoholTrackingViewModel()
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "wineglass.fill")
                .font(.system(size: 104))
                .foregroundStyle(.purple.gradient)
            Text("\(viewModel.todayDrinkCount)")
                .font(.system(size: 82, weight: .bold, design: .rounded).monospacedDigit())
            Text(viewModel.todayDrinkCount == 1 ? "drink today" : "drinks today")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Record a drink", systemImage: "plus.circle.fill") {
                Task { _ = await viewModel.recordDrink() }
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
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .safeAreaInset(edge: .top, spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)
        }
    }
}
