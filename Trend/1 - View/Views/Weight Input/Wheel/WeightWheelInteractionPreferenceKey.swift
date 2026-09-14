// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

/// Only the containing page is paused; the wheel itself remains interactive.
/// GestureState resets this preference on release, cancellation and removal.
struct WeightWheelInteractionPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        let next = nextValue()
        value = value || next
    }
}
