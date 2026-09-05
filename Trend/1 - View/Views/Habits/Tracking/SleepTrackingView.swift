// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct SleepTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .sleep)
    @Environment(ThemeManager.self) private var themeManager
    @State private var hours = 8.0
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var feedback = 0
    @State private var isCelebrating = false
    @State private var celebrationProgress = 0.0

    var body: some View {
        VStack(spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)

            Group {
                if showsSleepEntry {
                    sleepEntry
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    recordedSleep
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.hasCheckedInToday { hours = viewModel.todayValue }
        }
        .habitErrorAlert(viewModel)
        .sensoryFeedback(.success, trigger: feedback)
    }

    private var showsSleepEntry: Bool {
        !viewModel.hasCheckedInToday || isEditing
    }

    private var sleepEntry: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 100))
                .foregroundStyle(.indigo.gradient)
            Text(hours.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 78, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
            Text("hours of sleep")
                .font(.title3)
                .foregroundStyle(.secondary)
            Slider(value: $hours, in: 0...14, step: 0.5)
                .padding(.horizontal, 8)
            Button("Record my sleep", systemImage: "bed.double.fill") {
                recordSleep()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)
            Spacer()
        }
    }

    private var recordedSleep: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                if isCelebrating {
                    sleepCelebration
                }

                Circle()
                    .stroke(.indigo.opacity(0.20), lineWidth: 5)
                    .scaleEffect(1 + celebrationProgress * 0.36)
                    .opacity(isCelebrating ? 1 - celebrationProgress : 0)

                Circle()
                    .fill(.indigo.gradient)
                    .shadow(color: .indigo.opacity(0.24), radius: 24, y: 12)
                Image(systemName: "checkmark")
                    .font(.system(size: 78, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: feedback)
            }
            .frame(width: 190, height: 190)
            .transition(.scale(scale: 0.25).combined(with: .opacity))

            Text("Sleep recorded")
                .font(.largeTitle.bold())
            Text("\(viewModel.todayValue.formatted(.number.precision(.fractionLength(1)))) hours")
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(.indigo)
            Text("Your rest is recorded for today.")
                .foregroundStyle(.secondary)

            Spacer()
            Button("Edit sleep", systemImage: "pencil") {
                hours = viewModel.todayValue
                withAnimation(.easeInOut(duration: 0.25)) { isEditing = true }
            }
            .buttonStyle(.plain)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
        }
    }

    private func recordSleep() {
        guard !isSaving else { return }
        isSaving = true
        // Keep the entry state stable while persistence updates the observable
        // model. The explicit state change below can then own the transition.
        isEditing = true
        Task {
            defer { isSaving = false }
            await viewModel.record(hours)
            guard viewModel.errorMessage == nil else { return }
            feedback += 1
            isCelebrating = true
            celebrationProgress = 0
            withAnimation(.spring(response: 0.58, dampingFraction: 0.68)) {
                isEditing = false
            }
            await Task.yield()
            withAnimation(.easeOut(duration: 0.9)) {
                celebrationProgress = 1
            }
            try? await Task.sleep(for: .milliseconds(900))
            isCelebrating = false
            celebrationProgress = 0
        }
    }

    private var sleepCelebration: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                    .font(.system(size: index.isMultiple(of: 2) ? 18 : 9, weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 3) ? .yellow : .indigo)
                    .offset(y: -108 - celebrationProgress * 54)
                    .rotationEffect(.degrees(Double(index) * 30))
                    .scaleEffect(1 - celebrationProgress * 0.55)
                    .opacity(1 - celebrationProgress)
            }
        }
        .frame(width: 190, height: 190)
        .allowsHitTesting(false)
    }
}
