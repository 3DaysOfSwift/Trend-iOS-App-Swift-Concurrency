// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct DailyHabitsView: View {
    @State private var viewModel = DailyHabitsViewModel()
    @State private var showsLibrary = false
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if viewModel.isUnlocked {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Your daily habits", systemImage: "sun.max.fill").font(.title2.bold())
                        Spacer()
                        Button("Choose habits", systemImage: "slider.horizontal.3") { showsLibrary = true }
                            .labelStyle(.iconOnly)
                    }
                    Text("Small actions. Your own pace.").font(.subheadline).foregroundStyle(.secondary)
                    switch viewModel.loadState {
                    case .idle, .loading:
                        SwiftUI.ProgressView("Loading your habits…")
                    case .failed(let message):
                        Text(message).foregroundStyle(themeManager.palette.error)
                        Button("Retry") { Task { await viewModel.load() } }
                    case .ready:
                        if viewModel.habits.isEmpty {
                            Button("Choose one or two habits to begin", systemImage: "plus.circle") { showsLibrary = true }
                        }
                        ForEach(viewModel.habits) { habit in row(habit) }
                    }
                    Text("Record what happened, not what you think you should have done. Rest and recovery count too.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }
        }
        .task(id: viewModel.isUnlocked) { await viewModel.load() }
        .sheet(isPresented: $showsLibrary) { HabitLibraryView() }
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .sensoryFeedback(.success, trigger: viewModel.feedback)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.feedback)
    }

    private func row(_ habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: habit.symbol).foregroundStyle(themeManager.palette.accent)
                Text(habit.name).font(.headline)
                Spacer()
                if viewModel.savingIDs.contains(habit.id) { SwiftUI.ProgressView() }
            }
            Text(viewModel.description(for: habit, value: viewModel.value(for: habit)))
                .font(.title3.weight(.semibold)).contentTransition(.numericText())
            week(habit)
            controls(habit)
                .disabled(viewModel.savingIDs.contains(habit.id))
        }
        .padding(18)
        .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private func week(_ habit: Habit) -> some View {
        HStack {
            ForEach(viewModel.week(for: habit).days) { day in
                VStack(spacing: 6) {
                    Text(day.date, format: .dateTime.weekday(.narrow))
                        .font(.caption2.weight(day.isToday ? .bold : .regular))
                        .foregroundStyle(.secondary)
                    Text(weekMark(habit, value: day.hasCheckIn ? day.value : nil))
                        .font(.caption).lineLimit(1).minimumScaleFactor(0.7)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(day.isToday ? themeManager.palette.accent.opacity(0.12) : .clear, in: Circle())
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))), \(viewModel.description(for: habit, value: day.hasCheckIn ? day.value : nil))")
            }
        }
    }

    private func weekMark(_ habit: Habit, value: Double?) -> String {
        guard let value else { return "·" }
        if habit.type == .morningMood { return MorningMood(rawValue: Int(value))?.emoji ?? "·" }
        if habit.isDailyAnswer { return value == 1 ? "✓" : "–" }
        if habit.type == .wakeTime { return viewModel.description(for: habit, value: value) }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

    @ViewBuilder
    private func controls(_ habit: Habit) -> some View {
        if habit.isDailyAnswer {
            HStack {
                answer("Yes", value: 1, habit: habit)
                answer("No", value: 0, habit: habit)
            }
        } else if habit.type == .morningMood {
            HStack {
                ForEach(viewModel.moods, id: \.rawValue) { mood in
                    Button { record(habit, Double(mood.rawValue)) } label: {
                        Text(mood.emoji).font(.title).frame(maxWidth: .infinity, minHeight: 44)
                            .background(viewModel.value(for: habit) == Double(mood.rawValue) ? themeManager.palette.accent.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mood.title)
                    .accessibilityAddTraits(viewModel.value(for: habit) == Double(mood.rawValue) ? .isSelected : [])
                }
            }
        } else if habit.type == .water {
            Button("Record a glass", systemImage: "drop.fill") { record(habit, 1) }
                .buttonStyle(.bordered).controlSize(.large)
        } else if habit.type == .wakeTime {
            HStack {
                Picker("Hour", selection: hourBinding(habit)) {
                    ForEach(0..<24, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
                Text(":")
                Picker("Minute", selection: minuteBinding(habit)) {
                    ForEach(0..<60, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
                Button("Save") { record(habit, viewModel.draft(for: habit)) }.buttonStyle(.bordered)
            }
        } else {
            numericControls(habit)
        }
    }

    private func answer(_ title: String, value: Double, habit: Habit) -> some View {
        Button { record(habit, value) } label: {
            HStack {
                if viewModel.value(for: habit) == value { Image(systemName: "checkmark") }
                Text(title)
            }.frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .accessibilityAddTraits(viewModel.value(for: habit) == value ? .isSelected : [])
    }

    private func numericControls(_ habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if habit.type == .runningDistance {
                Picker("Distance unit", selection: $viewModel.distanceUnit) {
                    ForEach(RunningDistanceUnit.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented)
            }
            HStack {
                TextField(habit.unit, value: draftBinding(habit), format: .number)
                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    .accessibilityLabel("\(habit.name) value")
                Stepper("Adjust value", value: draftBinding(habit), in: habit.recordingPolicy.range, step: habit.recordingPolicy.step)
                    .labelsHidden()
                Button(habit.type == .sleep ? "Save" : "Add", systemImage: "plus") {
                    record(habit, viewModel.draft(for: habit))
                }.buttonStyle(.bordered)
            }
        }
    }

    private func draftBinding(_ habit: Habit) -> Binding<Double> {
        Binding(get: { viewModel.draft(for: habit) }, set: { viewModel.drafts[habit.id] = $0 })
    }

    private func hourBinding(_ habit: Habit) -> Binding<Int> {
        Binding(get: { Int(viewModel.draft(for: habit)) / 60 },
                set: { viewModel.drafts[habit.id] = Double($0 * 60 + Int(viewModel.draft(for: habit)) % 60) })
    }

    private func minuteBinding(_ habit: Habit) -> Binding<Int> {
        Binding(get: { Int(viewModel.draft(for: habit)) % 60 },
                set: { viewModel.drafts[habit.id] = Double(Int(viewModel.draft(for: habit)) / 60 * 60 + $0) })
    }

    private func record(_ habit: Habit, _ value: Double) {
        Task { await viewModel.record(habit, value: value) }
    }
}
