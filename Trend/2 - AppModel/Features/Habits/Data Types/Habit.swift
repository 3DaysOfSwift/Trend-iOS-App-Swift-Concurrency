// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct Habit: Codable, Identifiable, Equatable, Sendable {
    enum HabitType: String, Codable, CaseIterable, Sendable {
        case coffee, wakeTime, gymRepetitions, runningDistance, sleep, water, alcohol
    }

    let type: HabitType
    let id: String
    let name: String
    let prompt: String
    let unit: String
    let valueType: HabitValueType
    let desiredDirection: DesiredDirection
    let symbol: String
    let recordingPolicy: HabitRecordingPolicy

    static let allHabits: [Habit] = HabitType.allCases.map { Habit(type: $0) }

    init?(id: String) {
        guard let type = HabitType(rawValue: id) else { return nil }
        self.init(type: type)
    }

    init(type: HabitType) {
        self.type = type
        id = type.rawValue

        switch type {
        case .coffee:
            name = "Coffee"
            prompt = "How many cups of coffee today?"
            unit = "cups"
            valueType = .number
            desiredDirection = .lower
            symbol = "cup.and.saucer.fill"
            recordingPolicy = .init(defaultValue: 1, range: 0...99, step: 1, accumulatesOccurrences: false)
        case .wakeTime:
            name = "Wake time"
            prompt = "What time did you get up?"
            unit = ""
            valueType = .timeOfDay
            desiredDirection = .personalTarget
            symbol = "sunrise.fill"
            recordingPolicy = .init(defaultValue: 7 * 60, range: 0...(24 * 60 - 1), step: 1, accumulatesOccurrences: false)
        case .gymRepetitions:
            name = "Gym repetitions"
            prompt = "How many repetitions today?"
            unit = "reps"
            valueType = .number
            desiredDirection = .higher
            symbol = "dumbbell.fill"
            recordingPolicy = .init(defaultValue: 0, range: 0...10_000, step: 1, accumulatesOccurrences: false)
        case .runningDistance:
            name = "Running distance"
            prompt = "How far did you run today?"
            unit = "km"
            valueType = .number
            desiredDirection = .higher
            symbol = "figure.run"
            recordingPolicy = .init(defaultValue: 5, range: 0.1...200, step: 0.1, accumulatesOccurrences: true)
        case .sleep:
            name = "Sleep"
            prompt = "How many hours did you sleep?"
            unit = "hours"
            valueType = .number
            desiredDirection = .personalTarget
            symbol = "bed.double.fill"
            recordingPolicy = .init(defaultValue: 8, range: 0...24, step: 0.5, accumulatesOccurrences: false)
        case .water:
            name = "Water"
            prompt = "How many glasses of water today?"
            unit = "glasses"
            valueType = .number
            desiredDirection = .higher
            symbol = "drop.fill"
            recordingPolicy = .init(defaultValue: 1, range: 0...99, step: 1, accumulatesOccurrences: false)
        case .alcohol:
            name = "Alcohol"
            prompt = "How many alcoholic drinks today?"
            unit = "drinks"
            valueType = .number
            desiredDirection = .lower
            symbol = "wineglass.fill"
            recordingPolicy = .init(defaultValue: 1, range: 0...99, step: 1, accumulatesOccurrences: false)
        }
    }
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

struct HabitRecordingPolicy: Codable, Sendable, Equatable {
    let defaultValue: Double
    let range: ClosedRange<Double>
    let step: Double
    let accumulatesOccurrences: Bool

    func accepts(_ value: Double) -> Bool {
        value.isFinite && range.contains(value) &&
            abs((value / step).rounded() - value / step) < 0.000_001
    }
}
