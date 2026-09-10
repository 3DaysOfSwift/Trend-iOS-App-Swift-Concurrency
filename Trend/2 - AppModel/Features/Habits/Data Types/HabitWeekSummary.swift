// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct HabitWeekSummary: Equatable, Sendable {
    struct Day: Identifiable, Equatable, Sendable {
        var id: Date { date }
        let date: Date
        let value: Double
        let hasCheckIn: Bool
        let isToday: Bool
    }

    let currentStreak: Int
    let days: [Day]

    var totalValue: Double {
        days.reduce(0) { $0 + $1.value }
    }
}
