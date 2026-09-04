// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct HabitLibraryView: View {
    @State private var viewModel = HabitLibraryViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Trend works best when you begin with one or two things that genuinely matter to you. You can still choose as many as you like.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Choose your focus") {
                    ForEach(viewModel.templates) { template in
                        let habit = template.habit
                        Button { viewModel.toggle(template) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: habit.symbol)
                                    .frame(width: 30)
                                    .foregroundStyle(themeManager.palette.accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(habit.name).foregroundStyle(.primary)
                                    Text(directionDescription(habit.desiredDirection))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: viewModel.selection.contains(template.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.selection.contains(template.id) ? themeManager.palette.accent : .secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Choose Habits")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task { if await viewModel.save() { dismiss() } }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isSaving)
                }
            }
            .alert("Couldn’t save habits", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func directionDescription(_ direction: DesiredDirection) -> String {
        switch direction {
        case .higher: "Encourage an upward trend"
        case .lower: "Encourage a downward trend"
        case .personalTarget: "Observe your personal rhythm"
        }
    }
}
