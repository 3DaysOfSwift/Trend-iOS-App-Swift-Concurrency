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
                    ForEach(viewModel.habits) { habit in
                        Button { viewModel.toggle(habit) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: habit.symbol)
                                    .frame(width: 30)
                                    .foregroundStyle(themeManager.palette.accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(habit.name).foregroundStyle(.primary)
                                    Text(habit.prompt)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: viewModel.selection.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.selection.contains(habit.id) ? themeManager.palette.accent : .secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Your own daily habit") {
                    TextField("For example: Walk outside", text: $viewModel.customName)
                    Button("Add custom habit", systemImage: "plus.circle") { viewModel.addCustomDraft() }
                        .disabled(viewModel.customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
                    ForEach(Array(viewModel.customNames.enumerated()), id: \.offset) { index, name in
                        HStack {
                            Text(name)
                            Spacer()
                            Button("Remove", systemImage: "minus.circle") { viewModel.customNames.remove(at: index) }
                        }
                    }
                    Text("A simple Yes or No each day. Rest days are valid; you decide what fits your life.")
                        .font(.caption).foregroundStyle(.secondary)
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

}
