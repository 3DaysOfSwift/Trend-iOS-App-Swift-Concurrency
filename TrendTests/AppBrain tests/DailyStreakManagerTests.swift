// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct DailyStreakManagerTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func sevenDayBarShowsPositiveAndAttentionResults() async {
        let entries = [
            WeightEntry(date: date(day: 5), kilograms: 80),
            WeightEntry(date: date(day: 6), kilograms: 79),
            WeightEntry(date: date(day: 7), kilograms: 79.5)
        ]
        let manager = makeManager()

        await manager.refresh(entries: entries, now: date(day: 7, hour: 12))

        #expect(manager.snapshot.days.count == 7)
        #expect(manager.snapshot.days.prefix(3).map(\.result) == [
            .positive,
            .positive,
            .needsAttention
        ])
        #expect(manager.snapshot.currentStreak == 3)
    }

    @Test func streakRemainsAliveBeforeTodaysCheckIn() async {
        let entries = [
            WeightEntry(date: date(day: 5), kilograms: 80),
            WeightEntry(date: date(day: 6), kilograms: 79.8)
        ]
        let manager = makeManager()

        await manager.refresh(entries: entries, now: date(day: 7, hour: 12))

        #expect(manager.snapshot.currentStreak == 2)
        let today = manager.snapshot.days.first(where: \.isToday)
        #expect(today?.result == .noCheckIn)
    }

    @Test func missedPreviousDayBreaksTheStreak() async {
        let manager = makeManager()
        await manager.refresh(
            entries: [WeightEntry(date: date(day: 5), kilograms: 80)],
            now: date(day: 7, hour: 12)
        )

        #expect(manager.snapshot.currentStreak == 0)
    }

    private func makeManager() -> DailyStreakManager {
        DailyStreakManager(
            trend: DailyTrendManager(calendar: calendar),
            calendar: calendar
        )
    }

    private func date(day: Int, hour: Int = 8) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour))!
    }
}
