import Foundation
import Testing
@testable import Trend

struct ProgressInsightsTests {
    @Test func preparesAscendingPointsAndChange() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let entries = [
            WeightEntry(date: now, kilograms: 80),
            WeightEntry(date: now.addingTimeInterval(-86_400), kilograms: 82)
        ]
        let result = await ProgressInsights().prepare(entries: entries, range: .all, now: now)
        #expect(result.points.map(\.kilograms) == [82, 80])
        #expect(result.changeKilograms == -2)
        #expect(result.changeDirection == .improving)
        #expect(result.averageKilograms == 81)
    }

    @Test func filtersEntriesOutsideRange() async {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let entries = [
            WeightEntry(date: now, kilograms: 80),
            WeightEntry(date: now.addingTimeInterval(-40 * 86_400), kilograms: 90)
        ]
        let result = await ProgressInsights().prepare(entries: entries, range: .month, now: now)
        #expect(result.points.count == 1)
        #expect(result.changeKilograms == nil)
        #expect(result.changeDirection == nil)
    }

    @Test func projectsRecentDailyDirectionThirtyDaysForward() async {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let entries = (0..<4).map { offset in
            WeightEntry(
                date: now.addingTimeInterval(Double(offset - 3) * 86_400),
                kilograms: Double(82 - offset)
            )
        }

        let result = await ProgressInsights().prepare(
            entries: entries,
            range: .all,
            goalKilograms: 75,
            now: now
        )

        #expect(result.projectionPoints.count == 7)
        #expect(abs((result.projectedWeeklyChangeKilograms ?? 0) - -1.05) < 0.001)
        #expect(result.projectionDirection == .improving)
        #expect(result.projectionHorizonDays == 30)
        #expect(abs((result.projectedWeightKilograms ?? 0) - 74.5) < 0.001)
        #expect(result.projectedGoalDate != nil)
    }

    @Test func waitsForThreeSeparateDaysBeforeProjecting() async {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let entries = [
            WeightEntry(date: now.addingTimeInterval(-86_400), kilograms: 81),
            WeightEntry(date: now, kilograms: 80)
        ]

        let result = await ProgressInsights().prepare(entries: entries, range: .all, now: now)

        #expect(result.projectionPoints.isEmpty)
        #expect(result.projectedWeightKilograms == nil)
    }

    @Test func commentaryRecognisesDownwardTrendAndRecoveryAfterBump() async {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let weights = [82.0, 81.0, 81.5, 80.0]
        let entries = weights.enumerated().map { offset, weight in
            WeightEntry(
                date: now.addingTimeInterval(Double(offset - 3) * 86_400),
                kilograms: weight
            )
        }

        let result = await ProgressInsights().prepare(entries: entries, range: .all, now: now)

        #expect(result.commentary.contains("overall direction is downward"))
        #expect(result.commentary.contains("1 bump"))
        #expect(result.commentary.contains("turned downward again"))
    }

    @Test func projectionDoesNotAlterObservedChangeOrAverage() async {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let entries = [82.0, 81.0, 80.0].enumerated().map { offset, weight in
            WeightEntry(
                date: now.addingTimeInterval(Double(offset - 2) * 86_400),
                kilograms: weight
            )
        }

        let result = await ProgressInsights().prepare(entries: entries, range: .all, now: now)

        #expect(result.changeKilograms == -2)
        #expect(result.averageKilograms == 81)
    }

    @Test func chartDomainPreparedByAppBrainIncludesGoal() async {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let entries = [82.0, 81.0, 80.0].enumerated().map { offset, weight in
            WeightEntry(
                date: now.addingTimeInterval(Double(offset - 2) * 86_400),
                kilograms: weight
            )
        }

        let result = await ProgressInsights().prepare(
            entries: entries,
            range: .all,
            goalKilograms: 70,
            now: now
        )

        #expect(result.domain?.contains(70) == true)
    }
}
