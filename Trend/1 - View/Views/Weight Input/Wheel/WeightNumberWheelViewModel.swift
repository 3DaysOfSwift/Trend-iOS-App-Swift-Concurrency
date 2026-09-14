// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Observation

/// Presentation position only; moving a wheel never saves a weight entry.
@MainActor @Observable
final class WeightNumberWheelViewModel {
    var dragOffset: Double = 0
    private var startingValue: Int?
    let rowSpacing: Double = 122

    func neighbour(of value: Int, offset: Int, maximum: Int, repeats: Bool) -> Int? {
        let number = value + offset
        if repeats { return (number % 10 + 10) % 10 }
        return (0...maximum).contains(number) ? number : nil
    }

    /// Track movement relative to the start of this gesture, not a scroll view's
    /// first visible row. The selected number always settles at offset zero.
    func drag(translation: Double, selection: Int, maximum: Int, repeats: Bool) -> Int {
        if startingValue == nil { startingValue = selection }
        let start = startingValue ?? selection
        let requestedSteps = Int((-translation / rowSpacing).rounded())
        let next = repeats ? start + requestedSteps : min(maximum, max(0, start + requestedSteps))
        let consumedSteps = next - start
        dragOffset = translation + Double(consumedSteps) * rowSpacing
        if !repeats && consumedSteps != requestedSteps {
            dragOffset = min(30, max(-30, dragOffset * 0.2))
        }
        return repeats ? (next % 10 + 10) % 10 : next
    }

    func endDrag() {
        startingValue = nil
        dragOffset = 0
    }

    func adjustedValue(_ value: Int, increasing: Bool, maximum: Int, repeats: Bool) -> Int {
        let next = value + (increasing ? 1 : -1)
        return repeats ? (next + 10) % 10 : min(maximum, max(0, next))
    }
}
