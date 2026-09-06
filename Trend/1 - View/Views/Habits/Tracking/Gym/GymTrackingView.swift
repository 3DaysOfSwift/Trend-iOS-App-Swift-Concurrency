// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct GymTrackingView: View {
    @State private var viewModel = GymTrackingViewModel()
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 74))
                .foregroundStyle(themeManager.palette.accent)
            Text("\(Int(viewModel.todayValue))")
                .font(.system(size: 88, weight: .black, design: .rounded).monospacedDigit())
            Text("repetitions today").font(.title3).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                repetitionButton("+1", amount: 1)
                repetitionButton("+5", amount: 5)
                repetitionButton("+10", amount: 10)
            }
            Text("Finish a set. Add the reps. Keep moving.")
                .foregroundStyle(.secondary)
            Spacer()
            if viewModel.hasCheckedInToday {
                Button("Clear today’s repetitions") {
                    Task { await viewModel.clearRepetitions() }
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Gym Repetitions")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .safeAreaInset(edge: .top, spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)
        }
    }

    private func repetitionButton(_ title: String, amount: Double) -> some View {
        Button(title) { Task { _ = await viewModel.recordRepetitions(Int(amount)) } }
            .font(.title2.bold())
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}
