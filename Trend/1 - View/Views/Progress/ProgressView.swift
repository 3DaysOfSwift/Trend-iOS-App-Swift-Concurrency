// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct ProgressView: View {
    @State private var viewModel = ProgressViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("Period", selection: $viewModel.range) {
                        ForEach(ProgressRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.isLoading && viewModel.snapshot.points.isEmpty {
                        SwiftUI.ProgressView("Preparing progress…").frame(minHeight: 340)
                    } else if viewModel.snapshot.points.isEmpty {
                        ContentUnavailableView("No progress yet", systemImage: "chart.xyaxis.line", description: Text("Log weight to create your chart."))
                            .frame(minHeight: 340)
                    } else {
                        projectionHero(snapshot: viewModel.snapshot)
                        TrendChartView(data: TrendChartData(
                            snapshot: viewModel.snapshot,
                            goalKilograms: viewModel.goalKilograms,
                            unit: viewModel.unit
                        ))
                        .padding(.horizontal, -16)
                        summary(snapshot: viewModel.snapshot)
                        commentary(snapshot: viewModel.snapshot)
                    }
                }
                .padding()
            }
            .background(Color.trendBackground)
            .navigationTitle("Your Projection")
        }
    }

    private func projectionHero(snapshot: ProgressSnapshot) -> some View {
        VStack(spacing: 12) {
            if
                let projectedWeight = snapshot.projectedWeightKilograms,
                let weeklyChange = snapshot.projectedWeeklyChangeKilograms
            {
                Text("IF YOUR RECENT DIRECTION CONTINUES")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                Text(viewModel.unit.formatted(kilograms: projectedWeight))
                    .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(projectionColour(snapshot: snapshot))

                Text("projected in \(snapshot.projectionHorizonDays) days")
                    .font(.headline)

                Label(
                    "\(viewModel.unit.formatted(kilograms: weeklyChange, signed: true)) each week at your recent pace",
                    systemImage: projectionSymbol(snapshot: snapshot)
                )
                .foregroundStyle(projectionColour(snapshot: snapshot))
                .font(.subheadline.weight(.semibold))

                Text(snapshot.projectionMessage ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let goalDate = snapshot.projectedGoalDate {
                    Label(
                        "Your current direction reaches your goal around \(goalDate.formatted(.dateTime.month(.wide).day()))",
                        systemImage: "flag.checkered"
                    )
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                }
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.trendTeal)
                Text("Your projection is warming up")
                    .font(.title2.bold())
                Text(snapshot.projectionUnavailableMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.trendTeal.opacity(0.14), Color.trendSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func projectionColour(snapshot: ProgressSnapshot) -> Color {
        snapshot.projectionDirection == .worsening ? .orange : .green
    }

    private func projectionSymbol(snapshot: ProgressSnapshot) -> String {
        switch snapshot.projectionDirection {
        case .improving: "arrow.down.right"
        case .steady: "arrow.right"
        case .worsening: "arrow.up.right"
        case nil: "minus"
        }
    }

    private func summary(snapshot: ProgressSnapshot) -> some View {
        HStack(spacing: 12) {
            MetricCard(title: "CHANGE") {
                Text(snapshot.changeKilograms.map { viewModel.unit.formatted(kilograms: $0, signed: true) } ?? "—")
                    .font(.title3.bold()).monospacedDigit()
            }
            MetricCard(title: "AVERAGE") {
                Text(snapshot.averageKilograms.map { viewModel.unit.formatted(kilograms: $0) } ?? "—")
                    .font(.title3.bold()).monospacedDigit()
            }
        }
    }

    private func commentary(snapshot: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your progress, in words", systemImage: "quote.bubble.fill")
                .font(.headline)
                .foregroundStyle(Color.trendTeal)

            Text(snapshot.commentary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            Text("Based only on your recorded check-ins.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.trendTeal.opacity(0.13), Color.trendSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}
