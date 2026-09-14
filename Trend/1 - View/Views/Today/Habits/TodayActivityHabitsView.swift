// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct TodayActivityHabitsView: View {
    @State private var viewModel = TodayActivityHabitsViewModel()
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        if !viewModel.habits.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(viewModel.habits) { habit in
                    Button { Task { await viewModel.select(habit) } } label: {
                        VStack(spacing: 6) {
                            Text(viewModel.emoji(habit)).font(.largeTitle)
                            Text(habit.name).font(.caption).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(viewModel.isSelected(habit) ? themeManager.palette.accent.opacity(0.15) : .clear,
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay { if viewModel.savingIDs.contains(habit.id) { SwiftUI.ProgressView() } }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.savingIDs.contains(habit.id))
                    .accessibilityLabel(habit.name)
                    .accessibilityValue(viewModel.isSelected(habit) ? "Recorded" : "Not selected")
                    .accessibilityAddTraits(viewModel.isSelected(habit) ? .isSelected : [])
                }
            }
            .padding(18)
            .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 24))
            .habitErrorAlert(message: viewModel.errorMessage, dismiss: viewModel.dismissError)
            .sheet(isPresented: $viewModel.showsRunEntry) {
                NavigationStack {
                    RunEntryView()
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(themeManager.palette.background.ignoresSafeArea())
                        .navigationTitle("Record a run")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { viewModel.showsRunEntry = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}
