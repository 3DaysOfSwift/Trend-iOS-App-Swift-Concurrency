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
