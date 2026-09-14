// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct TodayHabitsView: View {
    @State private var viewModel = TodayHabitsViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if viewModel.isUnlocked {
                VStack(alignment: .leading, spacing: 16) {
                    switch viewModel.loadState {
                    case .idle, .loading:
                        SwiftUI.ProgressView("Loading your habits…")
                    case .failed(let message):
                        Text(message).foregroundStyle(themeManager.palette.error)
                        Button("Retry") { Task { await viewModel.load() } }
                    case .ready:
                        ForEach(viewModel.habits.filter { !$0.isDailyAnswer && $0.type != .runningDistance }) { habit in row(habit) }
                        TodayActivityHabitsView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }
        }
        .task(id: viewModel.isUnlocked) { await viewModel.load() }
        .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
        .sensoryFeedback(.success, trigger: viewModel.feedback)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.feedback)
    }

    private func row(_ habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: habit.symbol).foregroundStyle(themeManager.palette.accent)
                Text(habit.type == .morningMood ? "How did you wake up today?" : habit.name).font(.headline)
                Spacer()
                if viewModel.savingIDs.contains(habit.id) { SwiftUI.ProgressView() }
            }
            if habit.type != .morningMood {
                Text(viewModel.description(for: habit, value: viewModel.value(for: habit)))
                    .font(.title3.weight(.semibold)).contentTransition(.numericText())
            }
            controls(habit)
                .disabled(viewModel.savingIDs.contains(habit.id))
        }
        .padding(18)
        .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 24))
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

    private func record(_ habit: Habit, _ value: Double) {
        Task { await viewModel.record(habit, value: value) }
    }
}
