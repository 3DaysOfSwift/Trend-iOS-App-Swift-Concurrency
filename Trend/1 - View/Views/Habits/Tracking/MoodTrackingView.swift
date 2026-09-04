// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct MoodTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .mood)
    @Environment(ThemeManager.self) private var themeManager
    private let moods = [(1, "😞"), (2, "😕"), (3, "😐"), (4, "🙂"), (5, "🤩")]

    var body: some View {
        VStack(spacing: 34) {
            Spacer()
            Text("How do you feel?")
                .font(.largeTitle.bold())
            Text("Notice the feeling. You do not need to explain it.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                ForEach(moods, id: \.0) { value, emoji in
                    Button { Task { await viewModel.record(Double(value)) } } label: {
                        Text(emoji)
                            .font(.system(size: 44))
                            .padding(8)
                            .background(
                                viewModel.todayValue == Double(value)
                                    ? themeManager.palette.accent.opacity(0.20)
                                    : .clear,
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            if viewModel.hasCheckedInToday {
                Label("Mood recorded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(themeManager.palette.success)
                    .font(.headline)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Mood")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(viewModel)
    }
}
