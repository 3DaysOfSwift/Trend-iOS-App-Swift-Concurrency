// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct WaterTrackingView: View {
    @State private var viewModel = WaterTrackingViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDroppingWater = false
    @State private var dropletOffset: CGFloat = 0
    @State private var feedback = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(.cyan.opacity(0.14))
                Image(systemName: "drop.fill")
                    .font(.system(size: 92))
                    .foregroundStyle(.cyan.gradient)
                    .offset(y: dropletOffset)
                    .shadow(color: .cyan.opacity(isDroppingWater ? 0.35 : 0), radius: 16, y: 10)
            }
            .frame(width: 220, height: 220)
            .clipped()
            Text("\(viewModel.todayGlassCount) glasses")
                .font(.largeTitle.bold().monospacedDigit())
            Button("Another glass", systemImage: "plus.circle.fill") {
                dropWater()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .opacity(isDroppingWater ? 0 : 1)
            .allowsHitTesting(!isDroppingWater)
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
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .sensoryFeedback(.success, trigger: feedback)
        .safeAreaInset(edge: .top, spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)
        }
    }

    private func dropWater() {
        guard !isDroppingWater else { return }
        isDroppingWater = true

        var resetTransaction = Transaction()
        resetTransaction.disablesAnimations = true
        withTransaction(resetTransaction) {
            dropletOffset = reduceMotion ? -24 : -190
        }

        Task {
            await Task.yield()
            withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .bouncy(duration: 0.8, extraBounce: 0.12)) {
                dropletOffset = 0
            }

            let wasRecorded = await viewModel.recordGlass()
            try? await Task.sleep(for: reduceMotion ? .milliseconds(250) : .milliseconds(800))
            if wasRecorded { feedback += 1 }

            withAnimation(.easeInOut(duration: 0.2)) {
                isDroppingWater = false
            }
        }
    }
}
