// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct Habit: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let prompt: String
    let unit: String
    let valueType: HabitValueType
    let desiredDirection: DesiredDirection
    let symbol: String
}

enum HabitValueType: String, Codable, Sendable {
    case number
    case timeOfDay
    case rating
}

enum DesiredDirection: String, Codable, Sendable {
    case higher
    case lower
    case personalTarget
}

struct HabitEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let habitID: String
    let date: Date
    let value: Double
    let occurrenceCount: Int?

    init(id: UUID, habitID: String, date: Date, value: Double, occurrenceCount: Int? = nil) {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.value = value
        self.occurrenceCount = occurrenceCount
    }
}

enum RunningDistanceUnit: String, CaseIterable, Identifiable, Sendable {
    case kilometres
    case miles

    var id: Self { self }
    var title: String { rawValue.capitalized }

    func value(fromKilometres kilometres: Double) -> Double {
        self == .kilometres ? kilometres : kilometres / 1.609_344
    }

    func kilometres(from value: Double) -> Double {
        self == .kilometres ? value : value * 1.609_344
    }
}

struct HabitStore: Codable, Equatable, Sendable {
    var habits: [Habit]
    var entries: [HabitEntry]
}

struct HabitWeekSnapshot: Equatable, Sendable {
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

struct HabitLifetimeSummary: Equatable, Sendable {
    let totalValue: Double
    let firstEntryDate: Date?
}
