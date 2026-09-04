// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct WaterTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .water)
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(.cyan.opacity(0.14))
                Image(systemName: "drop.fill")
                    .font(.system(size: 92))
                    .foregroundStyle(.cyan.gradient)
            }
            .frame(width: 220, height: 220)
            Text("\(Int(viewModel.todayValue)) glasses")
                .font(.largeTitle.bold().monospacedDigit())
            Button("Another glass", systemImage: "plus.circle.fill") {
                Task { await viewModel.increment() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Text("A small pause to notice what you give your body.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Water")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(viewModel)
        .safeAreaInset(edge: .top, spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)
        }
    }
}
