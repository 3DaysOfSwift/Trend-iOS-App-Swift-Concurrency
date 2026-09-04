// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct WakeTimeTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .wakeTime)
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "sunrise.fill")
                .font(.system(size: 110))
                .symbolRenderingMode(.palette)
                .foregroundStyle(themeManager.palette.warning, themeManager.palette.accent)
            Text(viewModel.hasCheckedInToday ? "You greeted the day" : "A new day is waiting")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Record the moment you begin your day. No editing, no judgement—just awareness.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("I’m up", systemImage: "sun.max.fill") {
                Task { await viewModel.recordCurrentTime() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Wake Time")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(viewModel)
        .safeAreaInset(edge: .top, spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)
        }
    }
}
