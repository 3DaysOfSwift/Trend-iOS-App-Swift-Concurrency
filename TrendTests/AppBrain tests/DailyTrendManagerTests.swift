import Foundation
import Testing
@testable import Trend

struct DailyTrendManagerTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func firstCheckInIsPositive() async {
        let entry = WeightEntry(date: date(day: 1), kilograms: 80)
        let result = await makeManager().assess(entries: [entry], newestEntryID: entry.id)

        #expect(result.verdict == .positive)
        #expect(result.changeKilograms == nil)
    }

    @Test func lowerWeightIsPositive() async {
        let older = WeightEntry(date: date(day: 1), kilograms: 80)
        let newest = WeightEntry(date: date(day: 2), kilograms: 79.5)
        let result = await makeManager().assess(entries: [newest, older], newestEntryID: newest.id)

        #expect(result.verdict == .positive)
        #expect(result.changeKilograms == -0.5)
    }

    @Test func higherWeightNeedsAttention() async {
        let older = WeightEntry(date: date(day: 1), kilograms: 80)
        let newest = WeightEntry(date: date(day: 2), kilograms: 80.5)
        let result = await makeManager().assess(entries: [older, newest], newestEntryID: newest.id)

        #expect(result.verdict == .needsAttention)
        #expect(result.changeKilograms == 0.5)
    }

    @Test func stableWeightWithinFiveDaysIsPositive() async {
        let older = WeightEntry(date: date(day: 1), kilograms: 80)
        let newest = WeightEntry(date: date(day: 5), kilograms: 80.1)
        let result = await makeManager().assess(entries: [older, newest], newestEntryID: newest.id)

        #expect(result.verdict == .positive)
    }

    @Test func stableWeightBeyondFiveDaysNeedsAttention() async {
        let older = WeightEntry(date: date(day: 1), kilograms: 80)
        let newest = WeightEntry(date: date(day: 7), kilograms: 80.1)
        let result = await makeManager().assess(entries: [older, newest], newestEntryID: newest.id)

        #expect(result.verdict == .needsAttention)
        #expect(result.title == "Time for a reset")
    }

    private func makeManager() -> DailyTrendManager {
        DailyTrendManager(calendar: calendar)
    }

    private func date(day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day))!
    }
}
