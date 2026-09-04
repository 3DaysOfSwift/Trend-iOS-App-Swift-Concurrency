// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

struct HabitDayStreakBanner: View {
    let data: HabitWeekSnapshot
    let symbol: String
    var showsDailyCount = false
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .foregroundStyle(themeManager.palette.accent.gradient)
                Text("\(data.currentStreak)")
                    .font(.headline.bold().monospacedDigit())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(data.currentStreak) day streak")

            Divider()
                .frame(height: 34)

            ForEach(data.days) { day in
                VStack(spacing: 5) {
                    Text(day.date, format: .dateTime.weekday(.narrow))
                        .font(.caption2.weight(day.isToday ? .bold : .medium))
                        .foregroundStyle(day.isToday ? .primary : .secondary)
                    ZStack {
                        Circle()
                            .fill(day.hasCheckIn ? themeManager.palette.success : Color.secondary.opacity(0.08))
                        if day.hasCheckIn {
                            if showsDailyCount {
                                Text("\(min(Int(day.value), 9))")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        } else if day.isToday {
                            Circle()
                                .stroke(themeManager.palette.accent, lineWidth: 2)
                        }
                    }
                    .frame(width: 28, height: 28)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dayAccessibilityLabel(day))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func dayAccessibilityLabel(_ day: HabitWeekSnapshot.Day) -> String {
        let name = day.date.formatted(.dateTime.weekday(.wide))
        if showsDailyCount, day.hasCheckIn {
            return "\(name), \(Int(day.value)) coffees"
        }
        return day.hasCheckIn ? "\(name), checked in" : "\(name), not checked in"
    }
}
