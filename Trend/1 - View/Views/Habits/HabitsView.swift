// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct HabitsView: View {
    @State private var viewModel = HabitsViewModel()
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.isLoadingPurchase {
                    SwiftUI.ProgressView("Checking your purchase…")
                } else if !viewModel.hasUnlockedHabits {
                    paywall
                } else if viewModel.habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .background(themeManager.palette.background)
            .navigationTitle("Habits")
            .toolbar {
                if !viewModel.habits.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Choose habits", systemImage: "slider.horizontal.3") {
                            viewModel.isChoosingHabits = true
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isChoosingHabits) {
                HabitLibraryView()
            }
            .alert("Trend Habits", isPresented: Binding(
                get: { viewModel.purchaseMessage != nil },
                set: { if !$0 { viewModel.dismissPurchaseMessage() } }
            )) {
                Button("OK") { viewModel.dismissPurchaseMessage() }
            } message: {
                Text(viewModel.purchaseMessage ?? "")
            }
        }
    }

    private var paywall: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(themeManager.palette.accent.opacity(0.14))
                    Image(systemName: "scope")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(themeManager.palette.accent)
                }
                .frame(width: 144, height: 144)

                VStack(spacing: 10) {
                    Text(viewModel.productName)
                        .font(.largeTitle.bold())
                    Text(viewModel.productDescription)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    benefit("Choose one or many daily signals", symbol: "checkmark.circle.fill")
                    benefit("Use numbers, ratings and times", symbol: "chart.bar.fill")
                    benefit("Keep your history on this device", symbol: "lock.shield.fill")
                    benefit("Pay once—no subscription", symbol: "infinity")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Button {
                    Task { await viewModel.purchaseHabits() }
                } label: {
                    if viewModel.isPurchasing {
                        SwiftUI.ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Unlock for \(viewModel.productPrice)")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isPurchasing)

                Button("Restore Purchases") {
                    Task { await viewModel.restorePurchases() }
                }
                .font(.footnote.weight(.semibold))
                .disabled(viewModel.isPurchasing)

                Text("Payment will be charged to your App Store account. This non-consumable purchase can be restored on your devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }

    private func benefit(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .foregroundStyle(.primary)
            .symbolRenderingMode(.hierarchical)
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(themeManager.palette.accent.opacity(0.14))
                Image(systemName: "scope")
                    .font(.system(size: 58, weight: .medium))
                    .foregroundStyle(themeManager.palette.accent)
            }
            .frame(width: 132, height: 132)

            Text("Choose what matters now")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Begin with one or two daily signals. A smaller focus makes the direction easier to see.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button("Choose my habits") { viewModel.isChoosingHabits = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var habitList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("Small observations become visible direction.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(viewModel.habits) { habit in
                    NavigationLink { destination(for: habit) } label: { habitCard(habit) }
                        .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func habitCard(_ habit: Habit) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(themeManager.palette.accent.opacity(0.14))
                Image(systemName: habit.symbol)
                    .font(.title2)
                    .foregroundStyle(themeManager.palette.accent)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 5) {
                Text(habit.name).font(.headline)
                Text(viewModel.todaySummary(for: habit))
                    .font(.subheadline)
                    .foregroundStyle(viewModel.hasCheckedIn(habit) ? themeManager.palette.success : .secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func destination(for habit: Habit) -> some View {
        switch HabitTemplate(rawValue: habit.id) {
        case .coffee: CoffeeTrackingView()
        case .wakeTime: WakeTimeTrackingView()
        case .gymRepetitions: GymTrackingView()
        case .runningDistance: RunningTrackingView()
        case .mood: MoodTrackingView()
        case .sleep: SleepTrackingView()
        case .water: WaterTrackingView()
        case .alcohol: AlcoholTrackingView()
        case nil: ContentUnavailableView("Tracker unavailable", systemImage: "exclamationmark.triangle")
        }
    }
}
