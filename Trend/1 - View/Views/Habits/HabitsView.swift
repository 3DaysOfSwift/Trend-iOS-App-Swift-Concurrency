// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct HabitsView: View {
    @State private var viewModel = HabitsViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @State private var isCompletingPurchase = false
    @State private var showsUnlockJourney = false
    @State private var showsThankYou = true
    @State private var thankYouStage = 0
    @State private var unlockStage = 0
    @State private var unlockFeedback = 0

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.isLoadingPurchase {
                    SwiftUI.ProgressView("Checking your purchase…")
                } else if showsUnlockJourney {
                    unlockJourney
                } else if !viewModel.hasUnlockedHabits || isCompletingPurchase {
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
                if !showsUnlockJourney, !viewModel.habits.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Choose habits", systemImage: "slider.horizontal.3") {
                            viewModel.isChoosingHabits = true
                        }
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
        .sensoryFeedback(.success, trigger: unlockFeedback)
    }

    private var paywall: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(themeManager.palette.accent.opacity(0.14))
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 58, weight: .medium))
                        .foregroundStyle(themeManager.palette.accent)
                }
                .frame(width: 144, height: 144)

                VStack(spacing: 10) {
                    Text(viewModel.productName)
                        .font(.largeTitle.bold())
                    Text("Make every set count. Record your repetitions and watch consistency become visible.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    benefit("Track your reps in the gym", symbol: "dumbbell.fill")
                    benefit("Coffee and water trackers included", symbol: "gift.fill")
                    benefit("See your consistency over time", symbol: "chart.xyaxis.line")
                    benefit("Pay once—no subscription", symbol: "infinity")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Button {
                    beginPurchase()
                } label: {
                    if viewModel.isPurchasing || isCompletingPurchase {
                        SwiftUI.ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Unlock for \(viewModel.productPrice)")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isPurchasing || isCompletingPurchase)

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

    private var unlockJourney: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 26) {
                    Spacer(minLength: 36)

                    purchaseLock

                    if showsThankYou {
                        thankYouContent
                            .transition(.opacity)
                    } else {
                        unlockedFeatureContent
                            .transition(.opacity.combined(with: .offset(y: 18)))
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
            }

            confetti
                .allowsHitTesting(false)
        }
    }

    private var purchaseLock: some View {
        ZStack {
            Circle()
                .fill(themeManager.palette.success.opacity(0.13))
                .frame(width: 154, height: 154)
                .scaleEffect(thankYouStage >= 1 ? 1 : 0.72)

            Circle()
                .stroke(themeManager.palette.success.opacity(0.18), lineWidth: 4)
                .frame(width: 154, height: 154)
                .scaleEffect(thankYouStage >= 2 ? 1.34 : 0.88)
                .opacity(thankYouStage >= 2 ? 0 : 1)

            Image(systemName: thankYouStage >= 2 ? "lock.open.fill" : "lock.fill")
                .contentTransition(.symbolEffect(.replace))
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(themeManager.palette.success.gradient)
        }
        .frame(height: 174)
    }

    private var thankYouContent: some View {
        VStack(spacing: 26) {
            VStack(spacing: 12) {
                Text("Thank you")
                    .font(.largeTitle.bold())
                Text("Your support means a lot to us.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .opacity(thankYouStage >= 1 ? 1 : 0)
            .offset(y: thankYouStage >= 1 ? 0 : 12)

            Label("We’ll upgrade your Today screen too.", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(themeManager.palette.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: Capsule())
                .opacity(thankYouStage >= 3 ? 1 : 0)
                .offset(y: thankYouStage >= 3 ? 0 : 10)
        }
        .frame(minHeight: 290, alignment: .top)
    }

    private var unlockedFeatureContent: some View {
        VStack(spacing: 26) {
            VStack(spacing: 8) {
                Text("Feature Unlocked")
                    .font(.largeTitle.bold())
                Text("Your next level of daily tracking is ready.")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(themeManager.palette.accent)
                Text("Track your reps in the gym")
                    .font(.title.bold())
                Text("Record every set and turn your effort into a visible daily habit.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: themeManager.palette.accent.opacity(0.10), radius: 22, y: 10)
            .opacity(unlockStage >= 1 ? 1 : 0)
            .offset(y: unlockStage >= 1 ? 0 : 18)

            HStack(spacing: 14) {
                unlockedTreat(title: "Coffee", message: "Count this week’s cups", symbol: "cup.and.saucer.fill")
                unlockedTreat(title: "Water", message: "Notice every glass", symbol: "drop.fill")
            }
            .opacity(unlockStage >= 2 ? 1 : 0)
            .offset(y: unlockStage >= 2 ? 0 : 16)

            Button("Choose my habits", systemImage: "arrow.right.circle.fill") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showsUnlockJourney = false
                }
                viewModel.isChoosingHabits = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .opacity(unlockStage >= 3 ? 1 : 0)
            .offset(y: unlockStage >= 3 ? 0 : 12)
        }
    }

    private var confetti: some View {
        HStack(spacing: 15) {
            ForEach(0..<17, id: \.self) { index in
                Capsule()
                    .fill(confettiColor(at: index))
                    .frame(width: index.isMultiple(of: 3) ? 7 : 5, height: index.isMultiple(of: 2) ? 18 : 12)
                    .rotationEffect(.degrees(Double((index * 47) % 130) - 65))
                    .offset(y: Double((index * 19) % 55))
            }
        }
        .offset(y: thankYouStage >= 3 ? -88 : 70)
        .opacity(thankYouStage == 3 ? 1 : 0)
        .animation(.easeOut(duration: 0.75), value: thankYouStage)
    }

    private func confettiColor(at index: Int) -> Color {
        switch index % 5 {
        case 0: themeManager.palette.accent
        case 1: themeManager.palette.success
        case 2: .yellow
        case 3: .orange
        default: .pink
        }
    }

    private func unlockedTreat(title: String, message: String, symbol: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(themeManager.palette.accent)
            Text(title).font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func beginPurchase() {
        guard !isCompletingPurchase else { return }
        isCompletingPurchase = true
        Task {
            let wasPurchased = await viewModel.purchaseHabits()
            if wasPurchased {
                thankYouStage = 0
                showsThankYou = true
                unlockStage = 0
                showsUnlockJourney = true
                await Task.yield()
                await animatePurchaseJourney()
            }
            isCompletingPurchase = false
        }
    }

    private func animatePurchaseJourney() async {
        try? await Task.sleep(for: .milliseconds(160))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) { thankYouStage = 1 }

        try? await Task.sleep(for: .milliseconds(650))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) { thankYouStage = 2 }
        unlockFeedback += 1

        try? await Task.sleep(for: .milliseconds(520))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.76)) { thankYouStage = 3 }

        try? await Task.sleep(for: .milliseconds(1_650))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.55)) {
            thankYouStage = 4
            showsThankYou = false
        }

        await animateUnlockJourney()
    }

    private func animateUnlockJourney() async {
        try? await Task.sleep(for: .milliseconds(180))
        withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) { unlockStage = 1 }
        try? await Task.sleep(for: .milliseconds(520))
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { unlockStage = 2 }
        try? await Task.sleep(for: .milliseconds(480))
        withAnimation(.easeOut(duration: 0.35)) { unlockStage = 3 }
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
        case .sleep: SleepTrackingView()
        case .water: WaterTrackingView()
        case .alcohol: AlcoholTrackingView()
        case nil: ContentUnavailableView("Tracker unavailable", systemImage: "exclamationmark.triangle")
        }
    }
}
