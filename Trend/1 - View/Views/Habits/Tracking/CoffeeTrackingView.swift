// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct CoffeeTrackingView: View {
    @State private var viewModel = HabitCheckInViewModel(template: .coffee)
    @Environment(ThemeManager.self) private var themeManager
    @State private var feedback = 0
    @State private var isRecordingCoffee = false
    @State private var minimumVisibleCardCount = 1

    var body: some View {
        VStack(spacing: 0) {
            HabitDayStreakBanner(
                data: viewModel.weekSnapshot,
                symbol: viewModel.habit.symbol,
                showsDailyCount: true
            )

            ScrollView {
              VStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(Int(viewModel.todayValue))")
                        .font(.system(size: 76, weight: .bold, design: .rounded).monospacedDigit())
                    Text(viewModel.todayValue == 1 ? "coffee today" : "coffees today")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                ForEach(0..<visibleCardCount, id: \.self) { cardIndex in
                    CoffeeStampCard(
                        cardNumber: cardIndex + 1,
                        filledStampCount: filledStampCount(for: cardIndex),
                        isRecording: isRecordingCoffee,
                        canRemoveStamp: viewModel.todayValue > 0,
                        onStamp: recordCoffee,
                        onRemoveStamp: removeCoffee
                    )
                }

                if currentCardsAreFull {
                    Button("Add another card") {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            minimumVisibleCardCount = visibleCardCount + 1
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(themeManager.palette.accent)
                }

                Text("Tap an empty circle each time you finish a coffee.")
                    .foregroundStyle(.secondary)

                if let firstCoffeeDate = viewModel.lifetimeSummary.firstEntryDate {
                    Text(lifetimeCoffeeText(firstCoffeeDate: firstCoffeeDate))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
              }
              .frame(maxWidth: .infinity)
              .padding(.horizontal, 24)
              .padding(.vertical, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.palette.background.ignoresSafeArea())
        .navigationTitle(weeklyCoffeeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .habitErrorAlert(viewModel)
        .sensoryFeedback(.success, trigger: feedback)
    }

    private var visibleCardCount: Int {
        max(minimumVisibleCardCount, max(1, Int(ceil(Double(viewModel.weeklyTotal) / 21))))
    }

    private var weeklyCoffeeTitle: String {
        let total = viewModel.weeklyTotal
        return "\(total) \(total == 1 ? "coffee" : "coffees")"
    }

    private var currentCardsAreFull: Bool {
        viewModel.weeklyTotal == visibleCardCount * 21
    }

    private func filledStampCount(for cardIndex: Int) -> Int {
        min(max(viewModel.weeklyTotal - cardIndex * 21, 0), 21)
    }

    private func lifetimeCoffeeText(firstCoffeeDate: Date) -> String {
        let total = Int(viewModel.lifetimeSummary.totalValue)
        let noun = total == 1 ? "coffee" : "coffees"
        let date = firstCoffeeDate.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(total) \(noun) since \(date)"
    }

    private func recordCoffee() {
        guard !isRecordingCoffee else { return }
        isRecordingCoffee = true
        feedback += 1

        Task {
            defer { isRecordingCoffee = false }
            await viewModel.increment()
        }
    }

    private func removeCoffee() {
        guard !isRecordingCoffee, viewModel.todayValue > 0 else { return }
        isRecordingCoffee = true
        feedback += 1

        Task {
            defer { isRecordingCoffee = false }
            await viewModel.removeOne()
        }
    }
}

private struct CoffeeStampCard: View {
    let cardNumber: Int
    let filledStampCount: Int
    let isRecording: Bool
    let canRemoveStamp: Bool
    let onStamp: () -> Void
    let onRemoveStamp: () -> Void
    @Environment(ThemeManager.self) private var themeManager

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(cardNumber == 1 ? "This week’s coffee card" : "Coffee card \(cardNumber)")
                    .font(.headline)
                Spacer()
                Text("\(filledStampCount) / 21")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<21, id: \.self) { index in
                    let isFilled = index < filledStampCount
                    Button(action: isFilled ? onRemoveStamp : onStamp) {
                        stamp(isFilled: isFilled)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRecording || (isFilled && !canRemoveStamp))
                    .scaleEffect(index == min(filledStampCount - 1, 20) ? 1 : 0.94)
                    .animation(.spring(response: 0.38, dampingFraction: 0.65), value: filledStampCount)
                    .accessibilityLabel(index < filledStampCount ? "Coffee stamp \(index + 1)" : "Empty coffee stamp")
                    .accessibilityHint(
                        index < filledStampCount
                            ? (canRemoveStamp ? "Removes one of today’s coffees" : "Recorded on an earlier day")
                            : "Records another coffee"
                    )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func stamp(isFilled: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isFilled ? themeManager.palette.accent : .clear)
                .overlay {
                    Circle()
                        .stroke(
                            isFilled ? themeManager.palette.accent : Color.secondary.opacity(0.24),
                            style: StrokeStyle(lineWidth: 1.5, dash: isFilled ? [] : [3, 3])
                        )
                }
            Image(systemName: "cup.and.saucer.fill")
                .font(.caption2.bold())
                .foregroundStyle(isFilled ? .white : Color.secondary.opacity(0.35))
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Circle())
    }
}
