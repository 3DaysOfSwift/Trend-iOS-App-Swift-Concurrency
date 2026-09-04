import Foundation

enum ProgressDirection: Sendable, Equatable {
    case improving
    case steady
    case worsening
}

struct ProgressSnapshot: Sendable, Equatable {
    struct Point: Identifiable, Sendable, Equatable {
        let id: UUID
        let date: Date
        let kilograms: Double
        let smoothedKilograms: Double
    }

    struct ProjectionPoint: Identifiable, Sendable, Equatable {
        var id: Date { date }
        let date: Date
        let kilograms: Double
    }

    let points: [Point]
    let changeKilograms: Double?
    let changeDirection: ProgressDirection?
    let averageKilograms: Double?
    let domain: ClosedRange<Double>?
    let projectionPoints: [ProjectionPoint]
    let projectedWeeklyChangeKilograms: Double?
    let projectionDirection: ProgressDirection?
    let projectedWeightKilograms: Double?
    let projectedGoalDate: Date?
    let projectionHorizonDays: Int
    let projectionUnavailableMessage: String
    let projectionMessage: String?
    let commentary: String

    static let empty = ProgressSnapshot(
        points: [],
        changeKilograms: nil,
        changeDirection: nil,
        averageKilograms: nil,
        domain: nil,
        projectionPoints: [],
        projectedWeeklyChangeKilograms: nil,
        projectionDirection: nil,
        projectedWeightKilograms: nil,
        projectedGoalDate: nil,
        projectionHorizonDays: 30,
        projectionUnavailableMessage: "Check in on three separate days and Trend will begin drawing your likely direction.",
        projectionMessage: nil,
        commentary: "Your story will begin with your first check-in."
    )
}

enum ProgressRange: String, CaseIterable, Identifiable, Sendable {
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"
    var id: Self { self }
    var days: Int? {
        switch self {
        case .month: 30
        case .threeMonths: 90
        case .sixMonths: 180
        case .year: 365
        case .all: nil
        }
    }
}
