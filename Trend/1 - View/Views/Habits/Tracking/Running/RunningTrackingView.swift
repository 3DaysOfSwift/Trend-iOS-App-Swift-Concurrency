// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct RunningTrackingView: View {
    @State private var viewModel = RunningTrackingViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @State private var distanceKilometres = 5.0
    @State private var selectedUnit = RunningDistanceUnit.kilometres
    @State private var isAddingAnotherRun = false
    @State private var isSaving = false
    @State private var feedback = 0
    @State private var isCelebrating = false
    @State private var celebrationProgress = 0.0

    var body: some View {
        VStack(spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)

            Group {
                if showsRunEntry {
                    runEntry
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    completedRun
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Running")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .sensoryFeedback(.success, trigger: feedback)
    }

    private var showsRunEntry: Bool {
        !viewModel.hasCheckedInToday || isAddingAnotherRun
    }

    private var displayedDistance: Binding<Double> {
        Binding(
            get: { selectedUnit.value(fromKilometres: distanceKilometres) },
            set: { distanceKilometres = selectedUnit.kilometres(from: $0) }
        )
    }

    private var maximumDistance: Double {
        selectedUnit == .kilometres ? 30 : 20
    }

    private var runEntry: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 104))
                .foregroundStyle(themeManager.palette.accent)

            Picker("Distance unit", selection: $selectedUnit) {
                ForEach(RunningDistanceUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            Text(displayedDistance.wrappedValue.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 78, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
            Text(selectedUnit.rawValue)
                .font(.title3)
                .foregroundStyle(.secondary)

            Slider(value: displayedDistance, in: 0.1...maximumDistance, step: 0.1)
                .padding(.horizontal, 8)

            Button("Record this run", systemImage: "checkmark.circle.fill") {
                recordRun()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)
            Spacer()
        }
    }

    private var completedRun: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                if isCelebrating {
                    runCelebration
                }

                Circle()
                    .stroke(themeManager.palette.success.opacity(0.24), lineWidth: 5)
                    .scaleEffect(1 + celebrationProgress * 0.40)
                    .opacity(isCelebrating ? 1 - celebrationProgress : 0)

                Circle()
                    .fill(themeManager.palette.success.gradient)
                    .shadow(color: themeManager.palette.success.opacity(0.24), radius: 24, y: 12)
                Image(systemName: "figure.run")
                    .font(.system(size: 76, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: feedback)
            }
            .frame(width: 190, height: 190)
            .transition(.scale(scale: 0.22).combined(with: .opacity))

            Text(viewModel.todayRunCount == 1 ? "Run complete" : "Runs complete")
                .font(.largeTitle.bold())
            Text("\(viewModel.todayRunCount) \(viewModel.todayRunCount == 1 ? "run" : "runs") today")
                .font(.title2.weight(.semibold))
                .foregroundStyle(themeManager.palette.success)
            Text(todayDistanceDescription)
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
            Button("Record another run") {
                distanceKilometres = 5
                withAnimation(.easeInOut(duration: 0.28)) { isAddingAnotherRun = true }
            }
            .buttonStyle(.plain)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
        }
    }

    private var todayDistanceDescription: String {
        let value = selectedUnit.value(fromKilometres: viewModel.todayValue)
            .formatted(.number.precision(.fractionLength(1)))
        return "\(value) \(selectedUnit.rawValue) today"
    }

    private func recordRun() {
        guard !isSaving else { return }
        isSaving = true
        // Keep the entry state visible while the observable model is updated.
        // The explicit state change below then owns the celebration transition.
        isAddingAnotherRun = true
        Task {
            defer { isSaving = false }
            if await viewModel.recordRun(kilometres: distanceKilometres) {
                feedback += 1
                isCelebrating = true
                celebrationProgress = 0
                withAnimation(.spring(response: 0.58, dampingFraction: 0.66)) {
                    isAddingAnotherRun = false
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
    }

    private var runCelebration: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "bolt.fill" : "sparkle")
                    .font(.system(size: index.isMultiple(of: 2) ? 11 : 18, weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 3) ? .yellow : themeManager.palette.success)
                    .offset(y: -108 - celebrationProgress * 58)
                    .rotationEffect(.degrees(Double(index) * 30))
                    .scaleEffect(1 - celebrationProgress * 0.55)
                    .opacity(1 - celebrationProgress)
            }
        }
        .frame(width: 190, height: 190)
        .allowsHitTesting(false)
    }
}
