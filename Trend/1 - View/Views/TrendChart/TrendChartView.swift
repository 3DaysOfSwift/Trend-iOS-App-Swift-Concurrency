// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Charts
import SwiftUI

/// Everything the reusable branded chart needs, without giving it access to a
/// ViewModel or the AppModel.
struct TrendChartData {
    let snapshot: ProgressSnapshot
    let goalKilograms: Double?
    let unit: WeightUnit
}

struct TrendChartView: View {
    let data: TrendChartData
    @State private var selectedDate: Date?
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your trend")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let change = data.snapshot.changeKilograms {
                    Text(data.unit.formatted(kilograms: change, signed: true))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(changeColour)
                }
            }
            .padding(.horizontal, 20)

            if !data.snapshot.points.isEmpty {
                chart
            } else {
                Text("Your chart will take shape after another check-in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 300, alignment: .center)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var chart: some View {
        Chart {
            if let onlyPoint = singlePoint {
                RuleMark(y: .value("Starting weight", onlyPoint.kilograms))
                    .foregroundStyle(themeManager.palette.chart)
                    .lineStyle(.init(lineWidth: 4, lineCap: .round))
            }

            ForEach(data.snapshot.points) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Chart minimum", domain.lowerBound),
                    yEnd: .value("Trend", point.smoothedKilograms)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.palette.chart.opacity(0.30), themeManager.palette.chart.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Trend", point.smoothedKilograms),
                    series: .value("Series", "Recorded trend")
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(themeManager.palette.chart)
                .lineStyle(.init(lineWidth: 4, lineCap: .round))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.kilograms)
                )
                .foregroundStyle(themeManager.palette.chart.opacity(0.38))
            }

            ForEach(data.snapshot.projectionPoints) { point in
                LineMark(
                    x: .value("Projected date", point.date),
                    y: .value("Projected weight", point.kilograms),
                    series: .value("Series", "Projection")
                )
                .interpolationMethod(.linear)
                .foregroundStyle(projectionColour)
                .lineStyle(.init(lineWidth: 3, lineCap: .round, dash: [7, 6]))
            }

            if let goal = data.goalKilograms {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(themeManager.palette.warning)
                    .lineStyle(.init(dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundStyle(themeManager.palette.warning)
                    }
            }
        }
        .chartYScale(domain: domain)
        .chartXScale(range: .plotDimension(startPadding: 12, endPadding: 12))
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .chartXSelection(value: $selectedDate)
        .frame(height: 340)
        .accessibilityLabel(
            "Weight history and 30-day projection chart with \(data.snapshot.points.count) entries"
        )
    }

    private var domain: ClosedRange<Double> { data.snapshot.domain ?? 0...100 }

    private var singlePoint: ProgressSnapshot.Point? {
        data.snapshot.points.count == 1 ? data.snapshot.points.first : nil
    }

    private var changeColour: Color {
        data.snapshot.changeDirection == .worsening
            ? themeManager.palette.error
            : themeManager.palette.success
    }

    private var projectionColour: Color {
        data.snapshot.projectionDirection == .worsening
            ? themeManager.palette.warning
            : themeManager.palette.success
    }
}
