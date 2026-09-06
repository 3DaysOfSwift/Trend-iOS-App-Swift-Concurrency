// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    @Environment(ThemeManager.self) private var themeManager
    @FocusState private var weightIsFocused: Bool
    @State private var showsDetails = false
    @State private var showsResult = false
    @State private var entryCardOffset: CGFloat = 0
    @State private var entryCardOpacity = 1.0
    @State private var themeChangeFeedback = 0

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.palette.background
                    .ignoresSafeArea()

                if viewModel.loadState == .idle || viewModel.loadState == .loading {
                    SwiftUI.ProgressView("Loading your weight history…")
                } else if case .failed(let message) = viewModel.loadState {
                    loadFailure(message)
                } else if showsResult, let result = viewModel.submittedResult {
                    resultContent(result)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    entryContent
                        .offset(y: entryCardOffset)
                        .opacity(entryCardOpacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                streakBar
            }
        }
        .task {
            async let load: Void = viewModel.loadIfRequired()
            async let focus: Void = focusWeightField()
            await load
            await focus
        }
        .sensoryFeedback(.selection, trigger: themeChangeFeedback)
    }

    private func loadFailure(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t load your weight history", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try again") {
                Task { await viewModel.retryLoad() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var streakBar: some View {
        let snapshot = viewModel.streakSnapshot

        return HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange.gradient)
                Text("\(snapshot.currentStreak)")
                    .font(.headline.bold().monospacedDigit())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(snapshot.currentStreak) day streak")

            Divider()
                .frame(height: 34)

            ForEach(snapshot.days) { day in
                VStack(spacing: 4) {
                    Text(day.date, format: .dateTime.weekday(.narrow))
                        .font(.system(size: 10, weight: day.isToday ? .bold : .medium))
                        .foregroundStyle(day.isToday ? Color.primary : Color.secondary)

                    streakSymbol(for: day)
                        .frame(width: 28, height: 28)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(streakAccessibilityLabel(for: day))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder
    private func streakSymbol(for day: DailyStreakSnapshot.Day) -> some View {
        switch day.result {
        case .positive:
            Circle()
                .fill(themeManager.palette.success.gradient)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                }
                .shadow(color: themeManager.palette.success.opacity(0.22), radius: 4, y: 2)
        case .needsAttention:
            Circle()
                .fill(themeManager.palette.error.gradient)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                }
                .shadow(color: themeManager.palette.error.opacity(0.22), radius: 4, y: 2)
        case .noCheckIn:
            Circle()
                .fill(Color.secondary.opacity(0.09))
                .overlay {
                    Circle()
                        .stroke(
                            day.isToday ? themeManager.palette.accent : Color.secondary.opacity(0.28),
                            lineWidth: day.isToday ? 2 : 1
                        )
                }
        }
    }

    private func streakAccessibilityLabel(for day: DailyStreakSnapshot.Day) -> String {
        let date = day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        switch day.result {
        case .positive: return "\(date), positive trend"
        case .needsAttention: return "\(date), trend needs attention"
        case .noCheckIn: return "\(date), no check-in"
        }
    }

    private var entryContent: some View {
        @Bindable var viewModel = viewModel

        return ScrollView {
            VStack(spacing: 22) {
                pageTitle

                Text("How much do you weigh today?")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                measurementCard

                DisclosureGroup(isExpanded: $showsDetails) {
                    VStack(spacing: 16) {
                        DatePicker(
                            "Date",
                            selection: $viewModel.draft.date,
                            in: ...viewModel.latestPermittedEntryDate
                        )
                        Divider()
                        TextField("Add a note (optional)", text: $viewModel.draft.note, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    .padding(.top, 14)
                } label: {
                    Label("Date and note", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                if let message = viewModel.errorMessage {
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.palette.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(themeManager.palette.error.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var measurementCard: some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 6) {
            Text("TODAY’S WEIGHT")
                .font(.caption.weight(.semibold))
                .tracking(1.8)
                .foregroundStyle(.white.opacity(0.68))

            TextField(
                "0.0",
                text: $viewModel.draft.value,
                prompt: Text("0.0").foregroundStyle(.white.opacity(0.24))
            )
            .keyboardType(.decimalPad)
            .focused($weightIsFocused)
            .multilineTextAlignment(.center)
            .font(.system(size: 104, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .tint(.white)
            .minimumScaleFactor(0.42)
            .lineLimit(1)
            .accessibilityLabel("Today’s weight")
            .accessibilityValue(
                viewModel.draft.value.isEmpty
                    ? "Not entered"
                    : "\(viewModel.draft.value) \(viewModel.unit.symbol)"
            )

            Text(viewModel.unit.symbol.uppercased())
                .font(.headline.monospaced())
                .tracking(2)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, minHeight: 230)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.palette.weightDisplayTop,
                            themeManager.palette.weightDisplayBottom
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                        .padding(1)
                }
                .shadow(color: themeManager.palette.accent.opacity(0.26), radius: 24, y: 12)
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: saveWeight) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.22), radius: 10, y: 5)

                    if viewModel.isSaving {
                        SwiftUI.ProgressView().tint(themeManager.palette.accent)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(themeManager.palette.accent)
                    }
                }
                .frame(width: 58, height: 58)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1 : 0.42)
            .accessibilityLabel(viewModel.isSaving ? "Saving weight" : "Submit weight")
            .padding(18)
        }
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .onTapGesture { weightIsFocused = true }
    }

    private func resultContent(_ result: DailyCheckInResult) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                pageTitle
                verdict(result.assessment)
                progressCard
                guidanceCard(
                    title: "Today’s tiny idea",
                    emoji: "💡",
                    item: result.tip,
                    tint: .yellow
                )
                guidanceCard(
                    title: "Pep Talk",
                    emoji: "🔥",
                    item: result.pepTalk,
                    tint: .orange
                )
                guidanceCard(
                    title: "Stop poisoning yourself",
                    emoji: "🛡️",
                    item: result.poisonPoint,
                    tint: .red
                )
                guidanceCard(
                    title: "Evolution",
                    emoji: "🧬",
                    item: result.evolutionPoint,
                    tint: .purple
                )
                if let fastingPoint = result.fastingPoint {
                    guidanceCard(
                        title: "Fasting",
                        emoji: "⏳",
                        item: fastingPoint,
                        tint: .blue
                    )
                }
                if let whatNext = result.whatNext {
                    whatNextCard(whatNext)
                }

                Button("Log another weight", action: beginAnotherCheckIn)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private var pageTitle: some View {
        Text("Today")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func verdict(_ assessment: DailyTrendAssessment) -> some View {
        let isPositive = assessment.verdict == .positive
        let colour = isPositive ? themeManager.palette.success : themeManager.palette.error

        return VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(colour.gradient)
                    .shadow(color: colour.opacity(0.30), radius: 24, y: 12)
                Image(systemName: isPositive ? "checkmark" : "xmark")
                    .font(.system(size: 82, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 172, height: 172)
            .accessibilityHidden(true)
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    themeManager.selectNextTheme()
                }
                themeChangeFeedback += 1
            }

            Text(assessment.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            if let change = assessment.changeKilograms {
                Text(viewModel.unit.formatted(kilograms: change, signed: true))
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(colour)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var progressCard: some View {
        TrendChartView(data: TrendChartData(
            snapshot: viewModel.progressSnapshot,
            goalKilograms: viewModel.goalKilograms,
            unit: viewModel.unit
        ))
        .padding(.horizontal, -20)
    }

    private func guidanceCard(
        title: String,
        emoji: String,
        item: WellnessTip,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(emoji).font(.title)
                Text(title).font(.headline)
            }

            Text(item.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            Text("General information—not medical advice.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            tint.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(tint.opacity(0.32), lineWidth: 1)
        }
    }

    private func whatNextCard(_ guidance: WhatNextGuidance) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("✨").font(.title)
                Text("What next?").font(.headline)
            }

            Text(guidance.opening)
                .font(.title3.weight(.semibold))

            Text(guidance.identity)

            Text(guidance.progression)
                .fontWeight(.medium)

            Text(guidance.closing)
                .font(.headline)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            themeManager.palette.success.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.palette.success.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func saveWeight() {
        weightIsFocused = false
        Task {
            guard await viewModel.save() else { return }

            withAnimation(.easeIn(duration: 0.52)) {
                entryCardOffset = -850
                entryCardOpacity = 0
            }
            try? await Task.sleep(for: .milliseconds(420))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                showsResult = true
            }
        }
    }

    private func beginAnotherCheckIn() {
        viewModel.beginAnotherCheckIn()
        entryCardOffset = 80
        entryCardOpacity = 0
        showsResult = false

        withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
            entryCardOffset = 0
            entryCardOpacity = 1
        }
        Task { await focusWeightField() }
    }

    private func focusWeightField() async {
        guard !showsResult else { return }
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        weightIsFocused = true
    }
}
