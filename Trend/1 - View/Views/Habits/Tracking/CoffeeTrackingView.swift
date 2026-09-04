// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct CoffeeTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .coffee)
    @Environment(ThemeManager.self) private var themeManager
    @State private var feedback = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("\(Int(viewModel.todayValue))")
                .font(.system(size: 76, weight: .bold, design: .rounded).monospacedDigit())
            Text(viewModel.todayValue == 1 ? "coffee today" : "coffees today")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                feedback += 1
                Task { await viewModel.increment() }
            } label: {
                ZStack {
                    Circle().fill(themeManager.palette.weightDisplayTop.gradient)
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                }
                .frame(width: 220, height: 220)
                .shadow(color: themeManager.palette.accent.opacity(0.28), radius: 28, y: 14)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: feedback)

            Text("Another coffee")
                .font(.title2.bold())
            Text("Tap once whenever you finish a cup.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle("Coffee")
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(viewModel)
    }
}
