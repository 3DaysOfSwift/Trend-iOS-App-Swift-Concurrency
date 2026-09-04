// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct HabitHistoryView: View {
    @State private var viewModel = HabitHistoryViewModel()

    var body: some View {
        Group {
            if viewModel.entries.isEmpty {
                ContentUnavailableView(
                    "No habit history",
                    systemImage: "scope",
                    description: Text("Your daily habit check-ins will appear here.")
                )
            } else {
                List(viewModel.entries) { entry in
                    if let habit = viewModel.habit(for: entry) {
                        HStack(spacing: 14) {
                            Image(systemName: habit.symbol)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(habit.name).font(.headline)
                                Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(viewModel.valueDescription(for: entry))
                                .font(.headline.monospacedDigit())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Habit History")
    }
}
