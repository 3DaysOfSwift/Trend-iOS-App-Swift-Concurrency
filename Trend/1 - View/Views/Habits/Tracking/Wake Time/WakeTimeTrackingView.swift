// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct WakeTimeTrackingView: View {
    @State private var viewModel = WakeTimeTrackingViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTime = Date.now
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var feedback = 0

    var body: some View {
        VStack(spacing: 0) {
            HabitDayStreakBanner(data: viewModel.weekSnapshot, symbol: viewModel.habit.symbol)

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: showsTimePicker ? "sun.horizon.fill" : "sunrise.fill")
                    .font(.system(size: 104))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(themeManager.palette.warning, themeManager.palette.accent)
                    .contentTransition(.symbolEffect(.replace))

                if showsTimePicker {
                    pickerContent
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    savedContent
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }

                Spacer()

                if viewModel.hasCheckedInToday, !showsTimePicker {
                    Button("Edit wake time", systemImage: "pencil") {
                        selectedTime = viewModel.timeForPicker
                        withAnimation(.easeInOut(duration: 0.25)) { isEditing = true }
                    }
                    .buttonStyle(.plain)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Wake Time")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .onAppear {
            selectedTime = viewModel.timeForPicker
        }
        .sensoryFeedback(.success, trigger: feedback)
    }

    private var showsTimePicker: Bool {
        isEditing || !viewModel.hasCheckedInToday
    }

    private var pickerContent: some View {
        VStack(spacing: 18) {
            Text("What time did you wake up?")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            DatePicker(
                "Wake time",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
            .environment(\.locale, Locale(identifier: "en_GB"))
            .frame(height: 150)
            .clipped()

            Button("Save wake time", systemImage: "checkmark.circle.fill") {
                saveWakeTime()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)

        }
    }

    private var savedContent: some View {
        VStack(spacing: 14) {
            Text("You greeted the day")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(viewModel.timeForPicker, format: .dateTime.hour().minute())
                .font(.system(size: 72, weight: .bold, design: .rounded).monospacedDigit())
                .environment(\.locale, Locale(identifier: "en_GB"))
            Text("Your wake time is recorded for today.")
                .foregroundStyle(.secondary)
        }
    }

    private func saveWakeTime() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            if await viewModel.recordTime(selectedTime) {
                feedback += 1
                withAnimation(.easeInOut(duration: 0.3)) { isEditing = false }
            }
        }
    }
}
