import Foundation

actor ProgressInsights {
    func prepare(
        entries: [WeightEntry],
        range: ProgressRange,
        goalKilograms: Double? = nil,
        now: Date = .now
    ) -> ProgressSnapshot {
        let ascending = entries.sorted { $0.date < $1.date }
        let filtered: [WeightEntry]
        if let days = range.days, let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) {
            filtered = ascending.filter { $0.date >= cutoff }
        } else {
            filtered = ascending
        }
        guard !filtered.isEmpty else { return .empty }

        let points = filtered.indices.map { index in
            let lowerBound = max(0, index - 2)
            let window = filtered[lowerBound...index]
            let average = window.map(\.kilograms).reduce(0, +) / Double(window.count)
            return ProgressSnapshot.Point(
                id: filtered[index].id,
                date: filtered[index].date,
                kilograms: filtered[index].kilograms,
                smoothedKilograms: average
            )
        }
        let projection = prepareProjection(
            entries: filtered,
            goalKilograms: goalKilograms,
            now: now
        )
        let observedWeights = filtered.map(\.kilograms)
        let change = observedWeights.count > 1 ? observedWeights.last! - observedWeights.first! : nil
        let chartWeights = observedWeights
            + projection.points.map(\.kilograms)
            + (goalKilograms.map { [$0] } ?? [])
        let padding = max((chartWeights.max()! - chartWeights.min()!) * 0.15, 1)
        return ProgressSnapshot(
            points: points,
            changeKilograms: change,
            changeDirection: change.map(direction(for:)),
            averageKilograms: observedWeights.reduce(0, +) / Double(observedWeights.count),
            domain: (chartWeights.min()! - padding)...(chartWeights.max()! + padding),
            projectionPoints: projection.points,
            projectedWeeklyChangeKilograms: projection.weeklyChange,
            projectionDirection: projection.weeklyChange.map(direction(for:)),
            projectedWeightKilograms: projection.points.last?.kilograms,
            projectedGoalDate: projection.goalDate,
            projectionHorizonDays: 30,
            projectionUnavailableMessage: "Check in on three separate days and Trend will begin drawing your likely direction.",
            projectionMessage: projection.weeklyChange.map {
                $0 < 0
                    ? "Keep stacking the same small, repeatable choices."
                    : "The projection is feedback, not fate. One useful change can turn the line."
            },
            commentary: prepareCommentary(entries: filtered, hasProjection: !projection.points.isEmpty)
        )
    }

    private func direction(for change: Double) -> ProgressDirection {
        if change < 0 { return .improving }
        if change > 0 { return .worsening }
        return .steady
    }

    private func prepareCommentary(entries: [WeightEntry], hasProjection: Bool) -> String {
        guard entries.count > 1, let first = entries.first, let latest = entries.last else {
            return "This is the first point in your story. Keep checking in and your direction will start to reveal itself."
        }

        let changes = zip(entries, entries.dropFirst()).map { $1.kilograms - $0.kilograms }
        let meaningfulChanges = changes.filter { abs($0) >= 0.2 }
        let upwardSteps = meaningfulChanges.filter { $0 > 0 }.count
        let downwardSteps = meaningfulChanges.filter { $0 < 0 }.count
        let overallChange = latest.kilograms - first.kilograms
        let projectionNote = hasProjection
            ? " There is now enough history for your projection to show where that direction could lead."
            : " A few more daily check-ins will make the picture and projection clearer."

        if overallChange < -0.2 {
            if upwardSteps == 0 {
                return "Your recorded direction is steadily downward. The line shows repeated lower check-ins—not perfection, but a pattern worth continuing." + projectionNote
            }
            if (meaningfulChanges.last ?? 0) < 0 {
                return "Your overall direction is downward, with \(upwardSteps) \(upwardSteps == 1 ? "bump" : "bumps") along the way. Your latest movement turned downward again, showing that a wobble did not become your direction." + projectionNote
            }
            return "Your overall direction is still downward. The latest check-in is a bump in that longer journey, so treat it as information rather than a verdict." + projectionNote
        }

        if overallChange > 0.2 {
            if downwardSteps > 0 {
                return "The recorded direction is currently upward, but the line also contains \(downwardSteps) downward \(downwardSteps == 1 ? "move" : "moves"). You have already shown that the direction can change; the next small choice can begin another turn." + projectionNote
            }
            return "Your recorded direction is currently upward. This is feedback, not failure—the line can only describe what has happened, and your next check-in has not been written yet." + projectionNote
        }

        return "Your weight is holding broadly steady. Consistency has kept the larger line calm; continued check-ins will reveal whether this is a pause or the beginning of a new direction." + projectionNote
    }

    private func prepareProjection(
        entries: [WeightEntry],
        goalKilograms: Double?,
        now: Date
    ) -> (points: [ProgressSnapshot.ProjectionPoint], weeklyChange: Double?, goalDate: Date?) {
        let calendar = Calendar.current
        let dailyEntries = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .values
            .compactMap { $0.max(by: { $0.date < $1.date }) }
            .sorted { $0.date < $1.date }
        let recent = Array(dailyEntries.suffix(14))

        guard recent.count >= 3, let first = recent.first, let latest = recent.last else {
            return ([], nil, nil)
        }

        let x = recent.map { $0.date.timeIntervalSince(first.date) / 86_400 }
        let y = recent.map(\.kilograms)
        let meanX = x.reduce(0, +) / Double(x.count)
        let meanY = y.reduce(0, +) / Double(y.count)
        let denominator = x.reduce(0) { $0 + pow($1 - meanX, 2) }
        guard denominator > 0 else { return ([], nil, nil) }

        let rawSlope = zip(x, y).reduce(0) { partial, pair in
            partial + ((pair.0 - meanX) * (pair.1 - meanY))
        } / denominator
        // Short-term water changes can create implausibly steep lines. Keep the
        // motivational forecast within a bounded illustrative range while more
        // daily observations accumulate.
        let slope = min(max(rawSlope, -0.15), 0.15)
        let horizonDays = 30
        let points = stride(from: 0, through: horizonDays, by: 5).compactMap { day -> ProgressSnapshot.ProjectionPoint? in
            guard let date = calendar.date(byAdding: .day, value: day, to: latest.date) else { return nil }
            return .init(date: date, kilograms: latest.kilograms + slope * Double(day))
        }

        let goalDate: Date?
        if let goalKilograms, slope < 0, goalKilograms < latest.kilograms {
            let days = (goalKilograms - latest.kilograms) / slope
            goalDate = days > 0 && days <= 365
                ? calendar.date(byAdding: .day, value: Int(days.rounded()), to: now)
                : nil
        } else {
            goalDate = nil
        }

        return (points, slope * 7, goalDate)
    }
}
