// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

enum HabitTemplate: String, CaseIterable, Identifiable, Sendable {
    case coffee
    case wakeTime
    case gymRepetitions
    case runningDistance
    case sleep
    case water
    case alcohol

    var id: String { rawValue }

    /// The AppModel owns valid values so every future UI (including watchOS)
    /// observes the same business rules.
    var recordingPolicy: HabitRecordingPolicy {
        switch self {
        case .coffee: .init(defaultValue: 1, range: 0...99, step: 1, accumulatesOccurrences: false)
        case .wakeTime: .init(defaultValue: 7 * 60, range: 0...(24 * 60 - 1), step: 1, accumulatesOccurrences: false)
        case .gymRepetitions: .init(defaultValue: 0, range: 0...10_000, step: 1, accumulatesOccurrences: false)
        case .runningDistance: .init(defaultValue: 5, range: 0.1...200, step: 0.1, accumulatesOccurrences: true)
        case .sleep: .init(defaultValue: 8, range: 0...24, step: 0.5, accumulatesOccurrences: false)
        case .water: .init(defaultValue: 1, range: 0...99, step: 1, accumulatesOccurrences: false)
        case .alcohol: .init(defaultValue: 1, range: 0...99, step: 1, accumulatesOccurrences: false)
        }
    }

    var habit: Habit {
        switch self {
        case .coffee:
            Habit(id: id, name: "Coffee", prompt: "How many cups of coffee today?", unit: "cups", valueType: .number, desiredDirection: .lower, symbol: "cup.and.saucer.fill")
        case .wakeTime:
            Habit(id: id, name: "Wake time", prompt: "What time did you get up?", unit: "", valueType: .timeOfDay, desiredDirection: .personalTarget, symbol: "sunrise.fill")
        case .gymRepetitions:
            Habit(id: id, name: "Gym repetitions", prompt: "How many repetitions today?", unit: "reps", valueType: .number, desiredDirection: .higher, symbol: "dumbbell.fill")
        case .runningDistance:
            Habit(id: id, name: "Running distance", prompt: "How far did you run today?", unit: "km", valueType: .number, desiredDirection: .higher, symbol: "figure.run")
        case .sleep:
            Habit(id: id, name: "Sleep", prompt: "How many hours did you sleep?", unit: "hours", valueType: .number, desiredDirection: .personalTarget, symbol: "bed.double.fill")
        case .water:
            Habit(id: id, name: "Water", prompt: "How many glasses of water today?", unit: "glasses", valueType: .number, desiredDirection: .higher, symbol: "drop.fill")
        case .alcohol:
            Habit(id: id, name: "Alcohol", prompt: "How many alcoholic drinks today?", unit: "drinks", valueType: .number, desiredDirection: .lower, symbol: "wineglass.fill")
        }
    }
}

struct HabitRecordingPolicy: Sendable, Equatable {
    let defaultValue: Double
    let range: ClosedRange<Double>
    let step: Double
    let accumulatesOccurrences: Bool

    func accepts(_ value: Double) -> Bool {
        value.isFinite && range.contains(value) &&
            abs((value / step).rounded() - value / step) < 0.000_001
    }
}
